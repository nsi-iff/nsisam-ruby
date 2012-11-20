require "logger"
require "sinatra"
require "json"
require "thread"

module NSISam
  class Server < Sinatra::Application
    def storage
      @@storage ||= {}
    end

    def generate_key
      rand.to_s
    end

    post "/" do
      content_type :json
      incoming = JSON.parse(request.body.read)
      key = generate_key
      storage[key] = incoming['value'] unless incoming.has_key? 'expire'
      { key: key, checksum: "0" }.to_json
    end

    get "/" do
      content_type :json
      incoming = JSON.parse(request.body.read)
      key = incoming["key"]
      return 404 unless storage.has_key?(key)
      {
        metadata: "this is the metadata",
        data: storage[key]
      }.to_json
    end

    delete "/" do
      content_type :json
      incoming = JSON.parse(request.body.read)
      key = incoming["key"]
      return 404 unless storage.has_key?(key)
      storage.delete(key)
      { deleted: true }.to_json
    end

    put "/" do
      content_type :json
      incoming = JSON.parse(request.body.read)
      expire = incoming['expire']
      key = incoming["key"]
      return 404 unless storage.has_key?(key)
      if incoming.has_key? 'expire'
        storage.delete(key)
      else
        storage[key] = incoming['value']
      end
      { key: key, checksum: 0 }.to_json
    end
  end

  class FakeServerManager

    # Start the SAM fake server
    #
    # @param [Fixnum] port the port where the fake server will listen
    #   * make sure there's not anything else listenning on this port
    def start_server(port=8888)
      @thread = Thread.new do
        Server.run! :port => port
      end
      sleep(1)
      self
    end

    # Stop the SAM fake server
    def stop_server
      @thread.kill
      self
    end
  end
end
