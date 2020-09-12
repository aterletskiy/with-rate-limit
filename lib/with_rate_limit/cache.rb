module WithRateLimit
  class Cache
    def set(key, values)
      raise "Method 'set' must be implemented by a subclass"
    end
    
    def get(key)
      raise "Method 'get' must be implemented by a subclass"
    end
  end
end