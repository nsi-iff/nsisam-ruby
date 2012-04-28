module NSISam
  module Errors
    module Client
      class KeyNotFoundError < RuntimeError
      end

      class ChecksumMismatchError < RuntimeError
      end

      class MalformedRequestError < RuntimeError
      end

      class AuthenticationError < RuntimeError
      end

      class ConnectionRefusedError < RuntimeError
      end
    end
  end
end
