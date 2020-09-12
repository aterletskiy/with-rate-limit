module WithRateLimit
  class Strategy::Sleep < Strategy
    def self.execute(timeout)
      sleep timeout
    end
  end
end