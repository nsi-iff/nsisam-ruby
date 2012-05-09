module NSISam
  class FakeClient
    def initialize
      @storage = {}
    end

    def store(data)
      key = Time.now.to_i
      @storage[key] = data
      {'key' => key, 'checksum' => 0}
    end

    def get(key, expected_checksum=nil)
      if @storage.has_key?(key)
        {'data' => @storage[key]}
      else
        raise NSISam::Errors::Client::KeyNotFoundError
      end
    end

    def delete(key)
      if @storage.has_key?(key)
        @storage.delete key
        {'deleted' => true}
      else
        raise NSISam::Errors::Client::KeyNotFoundError
      end
    end

    def update(key, value)
      if @storage.has_key?(key)
        @storage[key] = value
        {'key' => key, 'checksum' => 0}
      else
        raise NSISam::Errors::Client::KeyNotFoundError
      end
    end
  end
end