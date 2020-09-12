require 'test_helper'

module WithRateLimit
  class Strategy::SleepTest < Minitest::Test
    def test_execute_sleep_for_given_duration
      timestamp_before = Time.now.to_i
      WithRateLimit::Strategy::Sleep.execute(2)
      timestamp_after = Time.now.to_i

      delta = timestamp_after - timestamp_before
      assert_equal 2, delta
    end
  end
end