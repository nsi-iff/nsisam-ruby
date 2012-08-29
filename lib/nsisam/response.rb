module NSISam
  # @attr [String] key The key of the stored data/file
  # @attr [String] checksum The checksum of the stored data/file
  # @attr [Hash, String, Array] data The stored object
  class Response
    def initialize(hash)
      @key, @checksum, @data, @deleted, @filename, @file = hash.values_at(
        'key', 'checksum', 'data', 'deleted', 'filename', 'file')
    end

    attr_reader :key, :checksum, :data, :filename, :file

    # Check if some data was deleted sucessfully 
    #
    # @return [Boolean] was the object deleted?
    #
    def deleted?
      !!@deleted
    end
  end
end