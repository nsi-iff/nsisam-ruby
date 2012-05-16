require "json"
require "net/http"
require "digest"

require File.dirname(__FILE__) + '/configuration'
require File.dirname(__FILE__) + '/errors'

module NSISam
  class Client

    # Initialize a client to a SAM node hosted at a specific url
    #
    # @param [Hash] optional hash with user, password, host and port of the SAM node
    # @return [Client] the object itself
    # @example
    #   nsisam = NSISam::Client.new user: 'username' password: 'pass',
    #                               host: 'localhost', port: '8888'
    def initialize(params = {})
      params = Configuration.settings.merge(params)
      @user = params[:user]
      @password = params[:password]
      @host = params[:host]
      @port = params[:port]
    end

    # Store a given data in SAM
    #
    # @param [String] data the desired data to store
    # @return [Hash] response with the data key and checksum
    #   * "key" [String] the key to access the stored data
    #   * "checksum" [String] the sha512 checksum of the stored data
    #
    # @raise [NSISam::Errors::Client::AuthenticationError] when user and password doesn't match
    #
    # @example
    #   nsisam.store("something")
    def store(data)
      request_data = {:value => data}.to_json
      request = prepare_request :PUT, request_data
      execute_request(request)
    end

    # Delete data at a given SAM key
    #
    # @param [Sring] key of the value to delete
    # @return [Hash] response
    #   * "deleted" [Boolean] true if the key was successfully deleted
    #
    # @raise [NSISam::Errors::Client::KeyNotFoundError] when the key doesn't exists
    # @raise [NSISam::Errors::Client::AuthenticationError] when user and password doesn't match
    #
    # @example Deleting an existing key
    #   nsisam.delete("some key")
    def delete(key)
      request_data = {:key => key}.to_json
      request = prepare_request :DELETE, request_data
      execute_request(request)
    end

    # Recover data stored at a given SAM key
    #
    # @param [String] key of the value to acess
    # @return [Hash] response
    #   * "from_user" [String] the user who stored the value
    #   * "date" [String] the date when the value was stored
    #   * "data" [String, Hash, Array] the data stored at that key
    #
    # @raise [NSISam::Errors::Client::KeyNotFoundError] when the key doesn't exists
    # @raise [NSISam::Errors::Client::AuthenticationError] when user and password doesn't match
    #
    # @example
    #   nsisam.get("some key")
    def get(key, expected_checksum=nil)
      request_data = {:key => key}.to_json
      request = prepare_request :GET, request_data
      response = execute_request(request)
      verify_checksum(response["data"], expected_checksum) unless expected_checksum.nil?
      response
    end

    # Update data stored at a given SAM key
    #
    # @param [String] key of the data to update
    # @param [String, Hash, Array] data to be stored at the key
    # @return [Hash] response
    #   * "key" [String] just to value key again
    #   * "checksum" [String] the new sha512 checksum of the key's data
    #
    # @raise [NSISam::Errors::Client::KeyNotFoundError] when the key doesn't exists
    # @raise [NSISam::Errors::Client::AuthenticationError] when user and password doesn't match
    #
    # @example
    #   nsisam.update("my key", "my value")
    def update(key, value)
      request_data = {:key => key, :value => value}.to_json
      request = prepare_request :POST, request_data
      execute_request(request)
    end

    # Pre-configure the NSISam module with default params for the NSISam::Client
    #
    # @yield a Configuration object (see {NSISam::Client::Configuration})
    #
    # @example
    #   NSISam::Client.configure do
    #     user     "why"
    #     password "chunky"
    #     host     "localhost"
    #     port     "8888"
    #   end
    def self.configure(&block)
      Configuration.instance_eval(&block)
    end

    private

    def prepare_request(verb, body)
      verb = verb.to_s.capitalize!
      request = Net::HTTP.const_get("#{verb}").new '/'
      request.body = body
      request.basic_auth @user, @password
      request
    end

    def execute_request(request)
      begin
        response = Net::HTTP.start @host, @port do |http|
          http.request(request)
        end
      rescue Errno::ECONNREFUSED => e
        raise NSISam::Errors::Client::ConnectionRefusedError
      else
        raise NSISam::Errors::Client::KeyNotFoundError if response.code == "404"
        raise NSISam::Errors::Client::MalformedRequestError if response.code == "400"
        raise NSISam::Errors::Client::AuthenticationError if response.code == "401"
        JSON.parse(response.body)
      end
    end

    def verify_checksum(data, expected_checksum)
      sha512_checksum = Digest::SHA512.hexdigest(data)
      raise NSISam::Errors::Client::ChecksumMismatchError unless sha512_checksum == expected_checksum
    end

  end
end
