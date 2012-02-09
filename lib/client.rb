require "json"
require "net/http"

module Client
  class Client

    def initialize(url)
      user_and_pass = url.match(/(\w+):(\w+)/)
      @user, @password = user_and_pass[1], user_and_pass[2]
      @url = url.match(/@(\w*)/)[1]
      @port = url.match(/[0-9]{4}/)[0]
    end

    def store(data)
      request_data = {:value => data}.to_json
      request = prepare_request :PUT, request_data
      execute_request(request)
    end

    def delete(key)
      request_data = {:key => key}.to_json
      request = prepare_request :DELETE, request_data
      execute_request(request)
    end

    def get(key)
      request_data = {:key => key}.to_json
      request = prepare_request :GET, request_data
      execute_request(request)
    end

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
      JSON.parse(response.body)
    end

  end
end
