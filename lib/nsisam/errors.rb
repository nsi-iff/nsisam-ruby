module NSISam
  module Errors
    module Client
      class KeyNotFoundError < RuntimeError
      end

      class ChecksumMismatchError < RuntimeError
      end
    end
  end
end
