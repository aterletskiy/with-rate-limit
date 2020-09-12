# with-rate-limit

`with-rate-limit` is a simple, lightweight and robust rate limiting tool. It supports in-memory or Redis
as a store for distributed operations. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'with_rate_limit'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install with_rate_limit

## Basic Usage

```ruby
include WithRateLimit

interval = 1 # interval in seconds
rate_limit = 5 # number of operations within given interval
options = {
  cache_key: "daily_requests", # default: "[limit]-operations-per-[interval]"
  strategy: WithRateLimit::Strategy::Sleep, # default strategy, see #strategies
  cache: WithRateLimit::Cache::Memory, # default cache mechanism, see #cache-mechanism
}
with_rate_limit interval, rate_limit, options do
  # do something here
  # operation performed here will be rated limited 
  # with `Sleep` strategy, if rate limit is hit, `with_rate_limit` will wait for the remainder of the interval.
end 
```

### Multiple rate limits
If you need to set up multiple rate limits, i.e. 5000 requests/day **and** 5 requests/sec, you can nest `with_rate_limit` calls.

```ruby
include WithRateLimit

with_rate_limit 1.day.to_i, 5000 do
    with_rate_limit 1, 5 do
        # do something here
    end
end
```

### Strategies
**WithRateLimit::Strategy::Sleep** 
Simply sleeps until the beginning of the next interval if rate limit is hit. Avoid `Sleep` with 
large intervals with limit that are likely to exceeded early as it may block application requests. 

**WithRateLimit::Strategy::RaiseError**
Raises an `WithRateLimit::LimitExceededError` with the number of second to wait until next interval.

```ruby
include WithRateLimit

with_rate_limit 1, 5 do
    # do something
rescue WithRateLimit::LimitExceededError => e  
    # reschedule this task for `e.timeout` seconds from now. 
end
```

Different strategies can be used in nested `with_rate_limit` calls.

### Cache 

**WithRateLimit::Cache::Memory**
Stores cache data for `cache_key` in memory.  

**WithRateLimit::Cache::Redis**
Stores cache data for `cache_key` in Redis so it can be shared in distributed systems.  Redis can be configured through
`WithRateLimit::Cache::Redis.configure` method.

```ruby
redis_cache = WithRateLimit::Cache::Redis.configure { |conf| conf[:redis_options] = {url: 'redis://localhost:6379'}}
with_rate_limit 1, 5, {cache: redis_cache} do
    # do something
end
```

Different cache mechanisms can be used in nested `with_rate_limit` calls too.

## Extending

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/aterletskiy/with_rate_limit. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/with_rate_limit/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the WithRateLimit project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/with_rate_limit/blob/master/CODE_OF_CONDUCT.md).
