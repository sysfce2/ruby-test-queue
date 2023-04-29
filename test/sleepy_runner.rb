$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require 'test_queue'
require 'test_queue/runner/minitest'

class SleepyTestRunner < TestQueue::Runner::Minitest
  def after_fork(num)
    if ENV['SLEEP_AS_RELAY'] && relay?
      sleep 5
    elsif ENV['SLEEP_AS_MASTER'] && !relay?
      sleep 5
    end
  end
end

SleepyTestRunner.new.execute
