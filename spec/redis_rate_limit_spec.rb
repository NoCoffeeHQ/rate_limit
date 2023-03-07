require 'spec_helper'
require 'redis'
require 'redis_rate_limit'

RSpec.describe RedisRateLimit::RateLimit do
  let(:redis) { Redis.new }
  let(:instance) { described_class.new('MyTask', max_rps: 3, redis: redis) }
  it 'accepts to pass a splat keyword arguments' do
    settings = { max_rps: 1, redis: redis }
    expect { described_class.new('TestClass', **settings) }.not_to raise_error
  end
  describe '#safe_call' do
    before { instance.reset }
    let(:action) { instance_double('Action') }
    subject { instance.safe_call { action.do } }
    context '1 call within a second' do
      it 'calls the action' do
        expect(action).to receive(:do).and_return(true)
        is_expected.to eq [:ok, true]
      end
    end
    context '3 calls within a second' do
      subject { 3.times.to_a.map { instance.safe_call { action.do } } }
      it 'calls the 3 actions' do
        expect(action).to receive(:do).exactly(3).and_return(true)
        is_expected.to eq([[:ok, true], [:ok, true], [:ok, true]])
      end
    end
    context '2 series of 5 calls within a second, delay of 1s between the 2 series' do
      subject { 10.times.each_with_index.map { |i| sleep(1) if i == 5; instance.safe_call { action.do } } }
      it 'calls only the first 3 actions' do
        expect(action).to receive(:do).exactly(6).and_return(true)
        is_expected.to eq([
          [:ok, true], [:ok, true], [:ok, true], [:error, 'Too many requests (max_rps: 3)'], [:error, 'Too many requests (max_rps: 3)'],
          [:ok, true], [:ok, true], [:ok, true], [:error, 'Too many requests (max_rps: 3)'], [:error, 'Too many requests (max_rps: 3)']
        ])
      end
    end
    context '2 calls within a second, delay of 1s, 2 more calls (exceeding the rpm limit), delay of 1s, one more call (exceeding the rpm limit)' do
      let(:instance) { described_class.new('AnotherMyTask', max_rps: 2, max_rpm: 3, redis: redis) }
      subject { 5.times.each_with_index.map { |i| sleep(1) if i == 2 || i == 4; instance.safe_call { action.do } } }
      it 'calls only the first 3 actions' do
        expect(action).to receive(:do).exactly(3).and_return(true)
        is_expected.to eq([
          [:ok, true], [:ok, true],
          [:ok, true], [:error, 'Too many requests (max_rpm: 3)'],
          [:error, 'Too many requests (max_rpm: 3)']
        ])
      end
    end
  end
end