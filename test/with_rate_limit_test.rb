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
  
    dummy = Dummy.new
    (rate_limit * runs).times.each do
      dummy.with_rate_limit(rate_limit_interval, rate_limit, {cache_key: "#{rate_limit}-operations-per-#{rate_limit_interval}-second"}) do
        operation_timestamps << Time.now.to_i
      end
    end
  
    assert_equal([
                   [(Time.now.to_i - rate_limit_interval * 2)] * rate_limit,
                   [(Time.now.to_i - rate_limit_interval)] * rate_limit,
                   [(Time.now.to_i)] * rate_limit
                 ].flatten, operation_timestamps.sort)
  end

  def test_executes_strategy_when_limit_is_hit_within_interval
    strategy = WithRateLimit::Strategy::Sleep
    cache = WithRateLimit::Cache::Memory
    rate_limit_interval = 1
    rate_limit = 1
    options = {strategy: strategy, cache: cache, cache_key: "#{rate_limit}-operations-per-#{rate_limit_interval}-second"}

    dummy = Dummy.new

    strategy.expects(:execute).with do |timeout|
      sleep timeout
    end

    dummy.with_rate_limit(rate_limit_interval, rate_limit, options) {}
    dummy.with_rate_limit(rate_limit_interval, rate_limit, options) {}
  end

  def test_increments_operation_count_without_updating_interval_start_timestamp_if_limit_not_exceeded
    strategy = WithRateLimit::Strategy::Sleep
    cache = WithRateLimit::Cache::Memory
    rate_limit_interval = 1
    rate_limit = 3
    key = "#{rate_limit}-operations-per-#{rate_limit_interval}-second"
    options = {strategy: strategy, cache: cache, cache_key: key}

    dummy = Dummy.new
    dummy.with_rate_limit(rate_limit_interval, rate_limit, options) {}
    timestamp_1 = cache.get(key)[:last_interval_started_at]
    assert_equal 1, cache.get(key)[:operations_count]

    dummy.with_rate_limit(rate_limit_interval, rate_limit, options) {}
    timestamp_2 = cache.get(key)[:last_interval_started_at]
    assert_equal 2, cache.get(key)[:operations_count]

    assert_equal timestamp_1, timestamp_2
  end

  def test_reset_cache_after_interval_has_passed
    strategy = WithRateLimit::Strategy::Sleep
    cache = WithRateLimit::Cache::Memory
    rate_limit_interval = 1
    rate_limit = 3
    key = "#{rate_limit}-operations-per-#{rate_limit_interval}-second"
    options = {strategy: strategy, cache: cache, cache_key: key}

    dummy = Dummy.new
    dummy.with_rate_limit(rate_limit_interval, rate_limit, options) {}
    dummy.with_rate_limit(rate_limit_interval, rate_limit, options) {}

    timestamp_1 = cache.get(key)[:last_interval_started_at]
    assert_equal 2, cache.get(key)[:operations_count]

    sleep rate_limit_interval

    dummy.with_rate_limit(rate_limit_interval, rate_limit, options) {}
    timestamp_2 = cache.get(key)[:last_interval_started_at]
    assert_equal 1, cache.get(key)[:operations_count]

    assert timestamp_2 > timestamp_1
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
