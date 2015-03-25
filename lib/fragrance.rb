require 'fragrance/version'
require 'aws-sdk'

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
              begin
                Timeout.timeout(30) do
                  deregister_instances_with_load_balancer(load_balancer, instance_id)
                  while ! load_balancer_instance_id_state(load_balancer, instance_id)
                    register_instances_with_load_balancer(load_balancer, instance_id)
                    until load_balancer_instance_id_state(load_balancer, instance_id)
                      sleep 5
                    end
                    sleep 5
                  end
                end
              rescue Timeout::Error
                puts 'Timed out waiting for instance to be added/removed from load balancer.'
                exit 1
              end
            end
          end
        end
      end
    end

    private

    def find_load_balancer_name_by_instance_id(instance_id)
      load_balancers = Array.new
      @elb.describe_load_balancers.data.first.each do |load_balancer|
        if load_balancer.instances.map(&:instance_id).to_s.include? instance_id
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

    def deregister_instances_with_load_balancer(load_balancer, instance_id)
      @elb.deregister_instances_with_load_balancer(
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