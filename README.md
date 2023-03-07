# RedisRateLimit

If an application goes beyond quota defined by public APIs, they might ban it. To overcome this issue, developers have to wrap each call to public APIs and make sure they don't make more requests than allowed.

Or in another words, this gem helps you to respect the ratio limit defined by external services like Twilio or others before your account gets suspended.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'redis_rate_limit'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redis_rate_limit

## Usage

```ruby
rate_limit = new('Twilio', max_rpm: 60, redis: $redis)

rate_limite.safe_call do 
  twilio_sdk.send_verification_sms('+123456789')
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/redis_rate_limit.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
