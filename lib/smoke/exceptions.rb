module Smoke
  class S3Exception < StandardError
    attr_reader :key, :message
    def initialize(key,message)
      @key = key
      super(message)
    end
  end
end