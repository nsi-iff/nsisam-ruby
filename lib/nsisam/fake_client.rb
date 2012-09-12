require 'json'
require 'base64'
require File.dirname(__FILE__) + '/response'
require 'fakeweb'

module NSISam
  class FakeClient

    attr_accessor :expire
    attr_reader :host, :port

    def initialize(host="localhost", port="8888")
      @storage = {}
      @host = host
      @port = port
    end

    def store(data)
      key = Time.now.nsec.to_s
      @storage[key] = JSON.load(data.to_json) unless @expire
      if data.kind_of?(Hash) and data.has_key?(:file) and data.has_key?(:filename)
        FakeWeb.register_uri(:get, "http://#{@host}:#{@port}/file/#{key}", body: Base64.decode64(data[:file]))
      end
      Response.new 'key' => key, 'checksum' => 0
    end

    def store_file(file, filename, type=:file)
      key = Time.now.to_i.to_s
      @storage[key] = {type.to_s => Base64.encode64(file), filename: filename}.to_json unless @expire
      FakeWeb.register_uri(:get, "http://#{@host}:#{@port}/file/#{key}", body: file)
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
        if @expire
          @storage.delete(key)
        else
          @storage[key] = value 
        end
        Response.new 'key' => key, 'checksum' => 0 
      else
        raise NSISam::Errors::Client::KeyNotFoundError
      end
    end
  end
end
