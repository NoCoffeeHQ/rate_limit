require 'redis_rate_limit/version'

module RedisRateLimit
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
      raise 'You must set at least a limit (max_rpd, max_rpm, max_rph or max_rps)' if @limits.map(&:last).all?(&:nil?)
    end
    def safe_call(&block)
      @limits.each do |(type, value)|
        next if value.nil? || value == 0
        _topic = "#{topic}-#{type}"
        current = redis.get(_topic).to_i
        if current >= value
          return [:error, "Too many requests (#{type}: #{value})"]
        else
          redis.multi do
            redis.incr(_topic)
            redis.expire(_topic, DURATION_IN_SECONDS[type])
          end
        end
      end
      [:ok, yield]
    end
    def reset
      @limits.each do |(type, _)|
        _topic = "#{topic}-#{type}"
        redis.set(_topic, 0)
      end
    end
  end
end
