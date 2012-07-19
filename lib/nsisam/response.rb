module NSISam
  class Response
    def initialize(hash)
      @key, @checksum, @data, @deleted = hash.values_at(
        'key', 'checksum', 'data', 'deleted')
    end

    attr_reader :key, :checksum, :data

    def deleted?
      !!@deleted
    end
  end
end
