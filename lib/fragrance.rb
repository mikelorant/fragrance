require 'fragrance/version'
require 'fragrance/core'
require 'fragrance/ec2'
require 'fragrance/elb'
require 'aws-sdk'
require 'pry'

module Fragrance
  # Fragrance::App
  class App
    def initialize
      @ec2 = Fragrance::Ec2.new
      @elb = Fragrance::Elb.new
    end

    def run
      ARGV.each do |instance_id|
        @elb.find_instance(instance_id).each do |load_balancer|
          if check(load_balancer, instance_id)
            refresh(load_balancer, instance_id)
          end
        end
      end
    end

    private

    def check(load_balancer, instance_id)
      puts "Found #{load_balancer}: #{instance_id}"
      (@elb.instance_state(load_balancer, instance_id) == 'OutOfService') &&
        (@ec2.state(instance_id) == 'running')
    end

    def refresh(load_balancer, instance_id)
      puts "Refreshing #{load_balancer}: #{instance_id}"
      @elb.reregister_instance(load_balancer, instance_id)
    end
  end
end
