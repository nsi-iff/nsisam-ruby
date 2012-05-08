module NSISam
  class Client
    class Configuration
      class << self
        def user(user = nil)
          @user = user unless user.nil?
          @user
        end

        def password(password = nil)
          @password = password unless password.nil?
          @password
        end

        def host(host = nil)
          @host = host unless host.nil?
          @host
        end

        def port(port = nil)
          @port = port unless port.nil?
          @port
        end

        def settings
          {user: @user, password: @password, host: @host, port: @port}
        end
      end
    end
  end
end
