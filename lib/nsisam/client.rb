require "json"
require "net/http"
require File.dirname(__FILE__) + '/errors'

module NSISam
  class Client

    # Initialize a client to a SAM node hosted at a specific url
    #
    # @param [String] url the SAM node url
    # @return [Client] the object itself
    def initialize(url)
      user_and_pass = url.match(/(\w+):(\w+)/)
      @user, @password = user_and_pass[1], user_and_pass[2]
      @url = url.match(/@(.*):/)[1]
      @port = url.match(/([0-9]+)(\/)?$/)[1]
    end

    # Store a given data in SAM
    #
    # @param [String] data the desired data to store
    # @return [Hash] response with the data key and checksum
    #   * "key" [String] the key to access the stored data
    #   * "checksum" [String] the sha1 checksum of the stored data 
    def store(data)
      request_data = {:value => data}.to_json
      request = prepare_request :PUT, request_data
      execute_request(request)
    end

    # Delete data at a given SAM key
    #
    # @param [Sring] key of the value to delete
    # @return [Hash] response
    #   * "deleted" [Boolean] true if the key was sucefully deleted 
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
    def get(key)
      request_data = {:key => key}.to_json
      request = prepare_request :GET, request_data
      execute_request(request)
    end

    # Update data stored at a given SAM key
    #
    # @param [String] key of the data to update
    # @param [String, Hash, Array] data to be stored at the key
    # return [Hash] response
    #   * "key" [String] just to value key again
    #   * "checksum" [String] the new sha1 checksum of the key's data
    def update(key, value)
      request_data = {:key => key, :value => value}.to_json
      request = prepare_request :POST, request_data
      execute_request(request)
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
      response = Net::HTTP.start @url, @port do |http|
        http.request(request)
      end
      raise NSISam::Errors::Client::KeyNotFoundError if response.code == "404"
      JSON.parse(response.body)
    end
  end
end
