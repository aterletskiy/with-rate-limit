module WithRateLimit
  class Cache::Memory < Cache
    def self.set(key, values)
      cache[key] = values
    end
    
    def self.get(key)
      cache[key]
    end
    
    def self.cache
      @cache ||= {}
    end
  end
end