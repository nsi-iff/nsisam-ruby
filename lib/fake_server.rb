require "logger"
require "sinatra"
require "json"
require "thread"
require "errors"

module FakeServer

  class Server < Sinatra::Application

    configure :development do
      Dir.mkdir('logs') unless File.exist?('logs')
      $stderr.reopen("logs/output.log", "w")
    end

    put "/" do
      content_type :json
      incoming = JSON.parse(request.body.read)
      {key: "value #{incoming["value"]} stored", checksum: "0"}.to_json
    end

    get "/" do
      content_type :json
      incoming = JSON.parse(request.body.read)
      return 404 if incoming["key"].include? "dont"
      {
        metadata: "this is the metadata",
        data: "data for key #{incoming["key"]}"
      }.to_json
    end

    delete "/" do
      content_type :json
      incoming = JSON.parse(request.body.read)
      return 404 if incoming["key"].include? "dont"
      deleted = incoming["key"].include?("delete")
      {deleted: deleted}.to_json
    end

    post "/" do
      content_type :json
      incoming = JSON.parse(request.body.read)
      return 404 if incoming["key"].include? "dont"
      {key: incoming["key"], checksum: 0}.to_json
    end
  end

  class FakeServerManager
    def start_server
      @thread = Thread.new do
        Server.run! :port => 8888
      end
      sleep(1)
      self
    end

    def stop_server
      @thread.kill
    end
  end
end

