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
    cache = options[:cache]
    cache_data = cache.get(cache_key).transform_keys(&:to_sym)
    
    last_interval_started_at = cache_data[:last_interval_started_at] || current_timestamp
    operations_count = cache_data[:operations_count].to_i
    timestamp = current_timestamp
    count_reset_delta = timestamp - last_interval_started_at
    interval = interval * 1000
  
    if (count_reset_delta < interval) && operations_count >= limit
      strategy.execute((interval - count_reset_delta) / 1000.0)
      return with_rate_limit(interval / 1000, limit, options, &block)
    elsif count_reset_delta > interval
      cache.set(cache_key, {last_interval_started_at: timestamp, operations_count: 1})
    else
      cache.set(cache_key, {last_interval_started_at: last_interval_started_at, operations_count: operations_count + 1})
    end
  
    begin
      yield
    rescue StandardError => e
      raise e
    end
  end
  
  private
  
  def current_timestamp
    DateTime.now.strftime('%Q').to_i
  end
  
  def default_options(interval, limit)
    {
      cache_key: "#{limit}-operations-per-#{interval}",
      strategy: WithRateLimit::Strategy::Sleep,
      cache: WithRateLimit::Cache::Memory
    }
  end
  
  def redis_client
    @redis_client ||= Redis.new(url: ENV['REDIS_HOST'])
  end
  
  def validate_options(options)
    raise "Invalid 'cache' option value.  Must be a subclass of WithRateLimit::Cache" unless options[:cache] < WithRateLimit::Cache
    raise "Invalid 'strategy' option value.  Must be a subclass of WithRateLimit::Strategy" unless options[:strategy] < WithRateLimit::Strategy
  end
end
