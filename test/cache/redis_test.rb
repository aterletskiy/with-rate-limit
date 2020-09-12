require 'test_helper'

module WithRateLimit
  class Cache::RedisTest < Minitest::Test
    def setup
      @redis_client = mock('redis-client')
      Redis.stubs(new: @redis_client)
      WithRateLimit::Cache::Redis.configure { |_| }
    end
    
    def test_set_updates_values_in_redis
      values = {a: 'a', b: 'b'}

      @redis_client.stubs(:exists).with('with-rate-limit').returns false
      @redis_client.expects(:set).with('with-rate-limit', JSON('test' => values))
      WithRateLimit::Cache::Redis.set('test', values)
    end
  
    def test_get_returns_cache_values_from_redis
      @redis_client.stubs(:exists).with('with-rate-limit').returns true
      @redis_client.expects(:get).with('with-rate-limit').returns JSON('test' => {a: 'a'})
      assert_equal({'a' => 'a'}, WithRateLimit::Cache::Redis.get('test'))
    end
  end
end