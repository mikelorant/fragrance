require 'aws-sdk'

module Fragrance
  # Fragrance::Core
  class Core
    def initialize
      Aws.config = {
        region: 'ap-southeast-2'
      }
    end
  end
end
