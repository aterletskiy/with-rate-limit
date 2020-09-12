require "redis"

module WithRateLimit
  class Cache::Redis < Cache
    def self.set(key, values)
      cache_data = cache
      cache_data[key] ||= {}
      cache_data[key].merge!(values)
      
      redis_client.set('with-rate-limit', JSON(cache_data))
    end
    
    def self.get(key)
      cache[key] || {}
    end
    
    def self.configure
      yield configuration
      return self
    end

    private
    
    def self.configuration
      @redis_client = nil
      @configuration ||= {}
    end

    def self.cache
      redis_client.exists('with-rate-limit') ? JSON(redis_client.get('with-rate-limit')) : {}
    end
    
    def self.redis_client
      @redis_client ||= ::Redis.new(configuration[:redis_options])
    end
  end
end