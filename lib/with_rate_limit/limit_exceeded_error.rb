module WithRateLimit
  class LimitExceededError < StandardError
    attr_accessor :timeout
    
    def initialize(timeout)
      @timeout = timeout
      
      super("Rate limit exceeded, #{timeout} second until next execution.")
    end
  end
end