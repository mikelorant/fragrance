# Fragrance::Aws

require 'aws-sdk'

module Fragrance
  class Core
    def initialize
      Aws.config = {
        region: 'ap-southeast-2'
      }
    end
  end
end