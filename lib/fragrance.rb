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
        @elb.instance(instance_id).each do |load_balancer|
          if @elb.instance_state(load_balancer, instance_id) == 'OutOfService'
            if @ec2.state(instance_id) == 'running'
              @elb.reregister(load_balancer, instance_id)
            end
          end
        end
      end
    end
  end
end

