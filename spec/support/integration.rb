require 'yaml'

module NSISam
  module Test
    module Helpers
      def integration_options
        YAML::load(File.open(config_file)).symbolize_keys if integrating?
      end
      
      def integrating?
        ENV['NSI_SAM_INTEGRATION'] && config_file_exists?
      end
      
      protected
      
      def config_file_exists?
        File.exists?(config_file)
      end
      
      def config_file
        File.expand_path(File.join(File.dirname(__FILE__), '..', 
          'integration.yml'))
      end
    end
  end
end
