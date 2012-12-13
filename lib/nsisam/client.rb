require "json"
require "net/http"
require "digest"
require "base64"

require File.dirname(__FILE__) + '/configuration'
require File.dirname(__FILE__) + '/errors'
require File.dirname(__FILE__) + '/response'

module NSISam
  class Client

    attr_accessor :expire

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
      @expire = params[:expire]
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
      request_data = {:value => data}
      request_data[:expire] = @expire if @expire
      request = prepare_request :POST, request_data.to_json
      Response.new(execute_request(request))
    end

    # Store a file in SAM. If the file will be used by other NSI's service
    # you should pass an additional 'type' parameter.
    #
    # @param [Object] file_content json serializable object
    # @param [Symbol] type of the file to be stored. Can be either :doc and :video.
    # @return [Response] object with access to the key and the sha512 checkum of the stored data
    #
    # @raise [NSISam::Errors::Client::AuthenticationError] when user and password doesn't match
    #
    # @example
    #   nsisam.store_file(File.read("foo.txt"))
    #   nsisam.store_file(File.read("foo.txt"), :video)
    def store_file(file_content, filename, type=:file)
      store(type => Base64.encode64(file_content), :filename => filename)
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
      Response.new(execute_request(request))
    end

    # Recover data stored at a given SAM key
    #
    # @param [String] key of the value to acess
    # @return [Response] response object holding the file and some metadata
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
      Response.new(response)
    end

    # Recover a file stored at a given SAM key
    #
    # @param [String] key of the file to access
    # @param [Symbol] type of the file to be recovered. Can be either :doc and :video.
    # @return [Response] response object holding the file and some metadata
    #
    # @raise [NSISam::Errors::Client::KeyNotFoundError] when the key doesn't exists
    # @raise [NSISam::Errors::Client::AuthenticationError] when user and password doesn't match
    #
    # @note Use of wrong "type" parameter can generate errors.
    #
    # @example
    #   nsisam.get_file("some key")
    #   nsisam.store_file("test", :doc) # stored at key 'test_key'
    #   nsisam.get_file("test_key", :doc)
    def get_file(key, type=:file, expected_checksum = nil)
      response = get(key, expected_checksum)
      response = Response.new(
        'key' => response.key,
        'checksum' => response.checksum,
        'filename' => response.data['filename'],
        'file' => Base64.decode64(response.data[type.to_s]),
        'deleted' => response.deleted?)
    end

    # Update data stored at a given SAM key
    #
    # @param [String] key of the data to update
    # @param [String, Hash, Array] data to be stored at the key
    # @return [Response] response object holding the file and some metadata
    #
    # @raise [NSISam::Errors::Client::KeyNotFoundError] when the key doesn't exists
    # @raise [NSISam::Errors::Client::AuthenticationError] when user and password doesn't match
    #
    # @example
    #   nsisam.update("my key", "my value")
    def update(key, value)
      request_data = {:key => key, :value => value}
      request_data[:expire] = @expire if @expire
      request = prepare_request :PUT, request_data.to_json
      Response.new(execute_request(request))
    end

    # Update file stored at a given SAM key
    #
    # @param [String] key of the file to update
    # @param [Symbol] type of the file to be recovered. Can be either :doc and :video.
    # @param [String] new_content content of the new file
    # @return [Response] response object holding the file and some metadata
    #
    # @raise [NSISam::Errors::Client::KeyNotFoundError] when the key doesn't exists
    # @raise [NSISam::Errors::Client::AuthenticationError] when user and password doesn't match
    #
    # @example
    #   nsisam.update_file("my key", "my value")
    #   nsisam.update_file("my key", "my value", :video)
    #   nsisam.update_file("my key", "my value", :doc)
    def update_file(key, type=:file, new_content, filename)
      encoded = Base64.encode64(new_content)
      update(key, type => encoded, filename: filename)
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

    def download_link_for_file(key)
      "http://#{@host}:#{@port}/file/#{key}"
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
        response = Net::HTTP.start @host, @port, :read_timeout => 60*60*30, :open_timeout => 60*60*30 do |http|
          http.request(request)
        end
        response
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
