require "redis_rate_limit/version"

module RedisRateLimit
  # If an application goes beyond quota defined by public APIs, they might ban it.
  # To overcome this issue, developers have to wrap each call to public APIs
  # and make sure they don't make more requests than allowed.
  #
  # This class is an implementation of https://redis.io/commands/INCR.
  #
  class RateLimit
    DURATION_IN_SECONDS = {
      max_rpd: 60 * 60 * 24,
      max_rph: 60 * 60,
      max_rpm: 60,
      max_rps: 1,
    }
    attr_reader :topic, :limits, :redis
    def initialize(topic, max_rpd: nil, max_rpm: nil, max_rph: nil, max_rps: nil, redis: nil)
      @topic, @redis = topic, redis
      @limits = [[:max_rps, max_rps], [:max_rpm, max_rpm], [:max_rph, max_rph], [:max_rpd, max_rpd]] # order is important
      raise 'You must set the redis option' if @redis.nil?
      raise 'You must set at least a limit (max_rpd, max_rpm, max_rph or max_rps)' if @limits.map(&:last).all?(&:blank?)
    end
    def safe_call(&block)
      @limits.each do |(type, value)|
        next if value.blank? || value == 0
        _topic = "#{topic}-#{type}"
        current = redis.llen(_topic)
        if current >= value
          return [:error, "Too many requests (#{type}: #{value})"]
        else
          if redis.exists(_topic) == false
            redis.multi do
              redis.rpush(_topic, _topic)
              redis.expire(_topic, DURATION_IN_SECONDS[type])
            end
          else
            redis.rpushx(_topic, _topic)
          end
        end
      end
      [:ok, yield]
    end
    def reset
      @limits.each do |(type, _)|
        _topic = "#{topic}-#{type}"
        redis.lrem(_topic, 0, _topic)
      end
    end
  end
end
