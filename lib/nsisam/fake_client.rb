module NSISam
  class Client
    def initialize(url)
      @storage = {}
    end

    def store(data)
      key = Time.now.to_i
      @storage[key] = data
      { 'key' => key, 'checksum' => 0 }
    end

    def delete(key)
      raise_if_doesnt_exist(key)
      @storage.delete(key)
      { 'deleted' => true }
    end

    def get(key)
      { 'data' => @storage[key] }
    end

    def update(key, value)
      raise_if_doesnt_exist(key)
      @storage[key] = value
      { 'key' => key, 'checksum' => 0 }
    end

    private

    def raise_if_doesnt_exist(key)
      raise NSISam::Errors::Client::KeyNotFoundError unless @storage.has_key?(key)
    end
  end
end
