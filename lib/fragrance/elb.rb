require 'aws-sdk'

module Fragrance
  class Elb < Core
    def initialize
      super

      @elb = Aws::ElasticLoadBalancing::Client.new
    end

    def instance(instance_id)
      load_balancers = []

      @load_balancers ||= @elb.describe_load_balancers.data.first
      @load_balancers.each do |load_balancer|
        if load_balancer.instances.map(&:instance_id).to_s.include? instance_id
          puts "Found #{load_balancer.load_balancer_name}: #{instance_id}"
          load_balancers << load_balancer.load_balancer_name
        end
      end

      load_balancers
    end

    def instance_state(load_balancer, instance_id)
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

    def reregister(load_balancer, instance_id)
      Timeout.timeout(30) do
        deregister(load_balancer, instance_id)
        register(load_balancer, instance_id)
        # ELB is slow to update the state even though the instance is
        # registered / deregistered. The following code should be uncommented
        # when there is a better way to determine the exact instance state.
        # while ! instance_state(load_balancer, instance_id)
        #   register(load_balancer, instance_id)
        #   until instance_state(load_balancer, instance_id)
        #     sleep 5
        #   end
        #   sleep 5
        # end
      end
    rescue Timeout::Error
      puts 'Timed out waiting for instance to be added/removed from load balancer.'
      exit 1
    end

    private

    def deregister(load_balancer, instance_id)
      @elb.deregister_instances_from_load_balancer(
        load_balancer_name: load_balancer,
        instances: [
          {
            instance_id: instance_id
          }
        ]
      )
    end

    def register(load_balancer, instance_id)
      @elb.register_instances_with_load_balancer(
        load_balancer_name: load_balancer,
        instances: [
          {
            instance_id: instance_id
          }
        ]
      )
    end
  end
end