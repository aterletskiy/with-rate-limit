require 'test_helper'

module WithRateLimit
  class Strategy::RaiseErrorTest < Minitest::Test
    def test_execute_raises_error_with_timeout
      error = assert_raises WithRateLimit::LimitExceededError do
        WithRateLimit::Strategy::RaiseError.execute(10)
      end
      
      assert_equal 10, error.timeout
    end
  end
end