module WithRateLimit
  class Strategy
    def self.execute(timeout)
      raise "Method 'execute' must be implemented by a subclass"
    end
  end
end