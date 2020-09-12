require "test_helper"

class WithRateLimitTest < Minitest::Test
  class Dummy
    include WithRateLimit
  end
  
  def test_that_it_has_a_version_number
    refute_nil ::WithRateLimit::VERSION
  end
  
  def test_limits_operations_to_given_limit_per_given_interval
    operation_timestamps = []
    rate_limit_interval = 1
    rate_limit = 2
    runs = 3
  
    Redis.new.del 'with-rate-limit'
  
    dummy = Dummy.new
    (rate_limit * runs).times.each do
      dummy.with_rate_limit(rate_limit_interval, rate_limit, {cache_key: '5-operations-per-second'}) do
        operation_timestamps << Time.now.to_i
      end
    end
  
    assert_equal([
                   [(Time.now.to_i - rate_limit_interval * 2)] * rate_limit,
                   [(Time.now.to_i - rate_limit_interval)] * rate_limit,
                   [(Time.now.to_i)] * rate_limit
                 ].flatten, operation_timestamps.sort)
  end
  
  def test_default_strategy_is_sleep
    WithRateLimit::Strategy::Sleep.expects(:execute).with do |timeout|
      assert_in_delta 1 , timeout, 0.05
      sleep timeout
    end
    
    dummy = Dummy.new
    2.times.each do |i|
      dummy.with_rate_limit(1, 1, {cache_key: '5-operations-per-second'}) {}
    end
  end

  class TestStrategy < WithRateLimit::Strategy
    def execute(timeout)
    end
  end
  def test_can_set_a_different_strategy
    TestStrategy.expects(:execute).with do |timeout|
      assert_in_delta 1 , timeout, 0.01
      sleep timeout
    end
    
    dummy = Dummy.new
    2.times.each do |i|
      dummy.with_rate_limit(1,1, {cache_key: 'test', strategy: TestStrategy}) {}
    end
  end
  
  class SomeTestClass; end
  def test_validates_cache_option
    dummy = Dummy.new
    error = assert_raises RuntimeError do
      dummy.with_rate_limit(1,1, {cache_key: 'test', cache: SomeTestClass}) {}
    end
    assert_equal "Invalid 'cache' option value.  Must be a subclass of WithRateLimit::Cache", error.message
  end
  
  def test_validates_strategy_option
    dummy = Dummy.new
    error = assert_raises RuntimeError, "Invalid 'strategy' option value.  Must be a subclass of WithRateLimit::Strategy" do
      dummy.with_rate_limit(1,1, {cache_key: 'test', strategy: SomeTestClass}) {}
    end
    assert_equal "Invalid 'strategy' option value.  Must be a subclass of WithRateLimit::Strategy", error.message
  end
end
