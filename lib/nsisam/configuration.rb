module NSISam
  class Client
    class Configuration
      class << self
        # Set the default {NSISam::Client} user
        #
        #
        # @param [String] user to set
        #
        # @return [String] the user set
        def user(user = nil)
          @user = user unless user.nil?
          @user
        end

        # Set the default {NSISam::Client} password
        #
        #
        # @param [String] password to set
        #
        # @return [String] the password set
        def password(password = nil)
          @password = password unless password.nil?
          @password
        end

        # Set the default {NSISam::Client} host
        #
        #
        # @param [String] host to set
        #
        # @return [String] the host set
        def host(host = nil)
          @host = host unless host.nil?
          @host
        end

        # Set the default {NSISam::Client} port
        #
        #
        # @param [String] port to set
        #
        # @return [String] the port set
        def port(port = nil)
          @port = port unless port.nil?
          @port
        end

        # Set the default {NSISam::Client} expire time
        #
        #
        # @param [Fixnum] expire time to set
        #
        # @return [Fixnum] the expire set
        def expire(expire = nil)
          @expire = expire unless expire.nil?
          @expire
        end

        # See how are the settings
        #
        # @return [Hash] actual settings
        def settings
          {user: @user, password: @password, host: @host, port: @port, expire: @expire}
        end
      end
    end
  end
end
