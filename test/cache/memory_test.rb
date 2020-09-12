require 'test_helper'

module WithRateLimit
  class Cache::Memory::RedisTest < Minitest::Test
    def test_set_updates_values_for_given_key
      values = {a: 'a', b: 'b'}
      WithRateLimit::Cache::Memory.set('test', values)
      assert_equal({'test' => values}, WithRateLimit::Cache::Memory.cache)
    end
    
    def test_get_returns_stored_values_for_given_key
      values = {a: 'a', b: 'b'}
      WithRateLimit::Cache::Memory.set('test', values)
      assert_equal values, WithRateLimit::Cache::Memory.get('test')
    end
  end
end