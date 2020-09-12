module WithRateLimit
  class Strategy::RaiseError < Strategy
    def self.execute(timeout)
      raise WithRateLimit::LimitExceededError.new(timeout)
    end
  end
end