# frozen_string_literal: true

require 'minitest'

case Minitest::VERSION.to_i
when 5
  require_relative '../runner/minitest5'
when 6
  require_relative '../runner/minitest6'
else
  raise 'requires Minitest version 5 or 6'
end

module TestQueue
  class Runner
    class Minitest < Runner
      def summarize_worker(worker)
        worker.summary = worker.lines.grep(/, \d+ errors?, /).first
        failures = worker.lines.select { |line|
          line if (line =~ /^Finished/) ... (line =~ /, \d+ errors?, /)
        }[1..-2]
        worker.failure_output = failures.join("\n") if failures
      end
    end
  end
end
