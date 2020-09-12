require "with_rate_limit/version"
require "with_rate_limit/limit_exceeded_error"
require "with_rate_limit/strategy"
require "with_rate_limit/strategy/raise_error"
require "with_rate_limit/strategy/sleep"
require "with_rate_limit/cache"
require "with_rate_limit/cache/memory"
require "with_rate_limit/cache/redis"
require "date"

module WithRateLimit
  def with_rate_limit(interval, limit, options = {}, &block)
    options = default_options(interval, limit).merge(options.transform_keys &:to_sym)
    validate_options(options)
    
    strategy = options[:strategy]
    cache_key = options[:cache_key]
    cache = rate_limit_cache(cache_key)
    last_interval_started_at = cache[:last_interval_started_at]
    operations_count = cache[:operations_count]
    timestamp = DateTime.now.strftime('%Q').to_i
    count_reset_delta = timestamp - last_interval_started_at
    interval = interval * 1000
  
    if (count_reset_delta < interval) && operations_count >= limit
      strategy.execute((interval - count_reset_delta) / 1000.0)
      return with_rate_limit(interval / 1000, limit, options, &block)
    elsif count_reset_delta > interval
      update_rate_limit_cache(cache_key, {last_interval_started_at: timestamp, operations_count: 1})
    else
      update_rate_limit_cache(cache_key, {operations_count: operations_count + 1})
    end
  
    begin
      yield
    # rescue Error::RateLimitError
    #   sleep [0, interval - count_reset_delta].max
    #   retry
    rescue StandardError => e
      raise e
    end
  end
  
  private
  
  def default_options(interval, limit)
    {
      cache_key: "#{limit}-operations-per-#{interval}",
      strategy: WithRateLimit::Strategy::Sleep,
      cache: WithRateLimit::Cache::Memory
    }
  end

  def rate_limit_cache(key)
    key = key.to_sym
    @rate_limit_cache = redis_client.exists('with-rate-limit') ? JSON(redis_client.get('with-rate-limit'), symbolize_names: true) : {}
    @rate_limit_cache[key] || update_rate_limit_cache(key, {last_interval_started_at: DateTime.now.strftime('%Q').to_i, operations_count: 0})
  end

  def update_rate_limit_cache(key, data)
    key = key.to_sym
    @rate_limit_cache = redis_client.exists('with-rate-limit') ? JSON(redis_client.get('with-rate-limit'), symbolize_names: true) : {}
    @rate_limit_cache.tap do |cache|
      cache[key] ||= {}
      cache[key].merge!(data)
      redis_client.set('with-rate-limit', JSON(cache))
    end
  
    @rate_limit_cache[key]
  end

  def redis_client
    @redis_client ||= Redis.new(url: ENV['REDIS_HOST'])
  end
  
  def validate_options(options)
    raise "Invalid 'cache' option value.  Must be a subclass of WithRateLimit::Cache" unless options[:cache] < WithRateLimit::Cache
    raise "Invalid 'strategy' option value.  Must be a subclass of WithRateLimit::Strategy" unless options[:strategy] < WithRateLimit::Strategy
  end
end
