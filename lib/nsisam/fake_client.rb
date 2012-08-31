require 'json'
require 'base64'
require File.dirname(__FILE__) + '/response'

module NSISam
  class FakeClient
    def initialize
      @storage = {}
    end

    def store(data)
      key = Time.now.to_i.to_s
      @storage[key] = JSON.load(data.to_json)
      Response.new 'key' => key, 'checksum' => 0
    end

    def store_file(file, type=:file)
      key = Time.now.to_i.to_s
      @storage[key] = {type.to_s => Base64.encode64(file)}.to_json
      Response.new "key" => key, "checksum" => 0
    end

    def get(key, expected_checksum=nil)
      if @storage.has_key?(key)
        Response.new 'data' => @storage[key]
      else
        raise NSISam::Errors::Client::KeyNotFoundError
      end
    end

    def get_file(key, type=:file)
      if @storage.has_key?(key)
        response = Hash.new 'data' => Base64.decode64(@storage[key][type.to_s])
        Response.new response
      else
        raise NSISam::Errors::Client::KeyNotFoundError
      end
    end

    def delete(key)
      if @storage.has_key?(key)
        @storage.delete key
        Response.new 'deleted' => true
      else
        raise NSISam::Errors::Client::KeyNotFoundError
      end
    end

    def update(key, value)
      if @storage.has_key?(key)
        @storage[key] = value
        Response.new 'key' => key, 'checksum' => 0
      else
        raise NSISam::Errors::Client::KeyNotFoundError
      end
    end
  end
end
