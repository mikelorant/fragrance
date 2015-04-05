require 'thor'

module Fragrance
  # Fragrance::Commandline
  class Commandline < Thor
    package_name 'Fragrance'
    map ['-v', '--version'] => :version

    desc 'version', 'Print the version and exit.'

    def version
      Fragrance::App.new.version
    end

    desc 'refresh', 'Refresh stopped instances in all load balancers.'

    method_option :instances,
                  type:     :array,
                  aliases:  '-i',
                  required: true,
                  desc:     'List of instances separated by spaces.'

    def refresh
      Fragrance::App.new.refresh(options[:instances])
    end
  end
end
