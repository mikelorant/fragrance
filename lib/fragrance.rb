require 'fragrance/version'
require 'aws-sdk'
require 'pry'

module Fragrance
  class App
    def initialize
      Aws.config = { region: 'ap-southeast-2' }

      @elb = Aws::ElasticLoadBalancing::Client.new
      @ec2 = Aws::EC2::Client.new
    end

    def run
      ARGV.each do |instance_id|
        find_load_balancer_name_by_instance_id(instance_id).each do |load_balancer|
          if load_balancer_instance_id_state(load_balancer, instance_id) == 'OutOfService'
            if instance_id_state(instance_id) == 'running'
              register_instances_with_load_balancer(load_balancer, instance_id)
            end
          end
        end
      end
    end

    private

    def find_load_balancer_name_by_instance_id(instance_id)
      load_balancers = Array.new

      @load_balancers ||= @elb.describe_load_balancers.data.first
      @load_balancers.each do |load_balancer|
        if load_balancer.instances.map(&:instance_id).to_s.include? instance_id
          puts "Found #{load_balancer.load_balancer_name}: #{instance_id}"
          load_balancers << load_balancer.load_balancer_name
        end
      end

      load_balancers
    end

    def load_balancer_instance_id_state(load_balancer, instance_id)
      @elb.describe_instance_health(
        load_balancer_name: load_balancer,
        instances: [
          {
            instance_id: instance_id
          }
        ]
      ).data.instance_states.first.state
    rescue Aws::ElasticLoadBalancing::Errors::InvalidInstance
      nil
    end

    def instance_id_state(instance_id)
      @ec2.describe_instance_status(
        instance_ids: [instance_id],
      ).data.instance_statuses.first.instance_state.name
    rescue NoMethodError
      nil
    end

    def reregister_instances_with_load_balancer(load_balancer, instance_id)
      Timeout.timeout(30) do
        deregister_instances_from_load_balancer(load_balancer, instance_id)
        register_instances_with_load_balancer(load_balancer, instance_id)
        # ELB is slow to update the state even though the instance is registered / deregistered.
        # The following code should be uncommented when there is a better way to determine
        # the exact instance state.
        # while ! load_balancer_instance_id_state(load_balancer, instance_id)
        #   register_instances_with_load_balancer(load_balancer, instance_id)
        #   until load_balancer_instance_id_state(load_balancer, instance_id)
        #     sleep 5
        #   end
        #   sleep 5
        # end
      end
    rescue Timeout::Error
      puts 'Timed out waiting for instance to be added/removed from load balancer.'
      exit 1
    end

    def deregister_instances_from_load_balancer(load_balancer, instance_id)
      @elb.deregister_instances_from_load_balancer(
        load_balancer_name: load_balancer,
        instances: [
          {
            instance_id: instance_id,
          }
        ]
      )
    end

    def register_instances_with_load_balancer(load_balancer, instance_id)
      @elb.register_instances_with_load_balancer(
        load_balancer_name: load_balancer,
        instances: [
          {
            instance_id: instance_id,
          }
        ]
      )
    end
  end
end
