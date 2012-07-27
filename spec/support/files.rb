require 'yaml'

module NSISam
  module Test
    module Helpers
      def example_file_content
        File.read(__FILE__)
      end
    end
  end
end
