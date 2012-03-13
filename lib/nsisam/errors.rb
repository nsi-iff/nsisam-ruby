module NSISam
  module Errors
    module Client
      class KeyNotFoundError < RuntimeError
      end

      class ChecksumMissmatchError < RuntimeError
      end
    end
  end
end
