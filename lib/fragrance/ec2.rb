# Fragrance::Ec2

require 'aws-sdk'

module Fragrance
  class Ec2 < Core
    def initialize
      super

      @ec2 = Aws::EC2::Client.new
    end

    def state(instance_id)
      @ec2.describe_instance_status(
        instance_ids: [instance_id]
      ).data.instance_statuses.first.instance_state.name
    rescue NoMethodError
      nil
    end
  end
end