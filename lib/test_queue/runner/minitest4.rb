# frozen_string_literal: true

require_relative '../runner'
require 'set'
require 'stringio'

class MiniTestQueueRunner < MiniTest::Unit
  def _run_suites(suites, type)
    self.class.output = $stdout

    if defined?(ParallelEach)
      # Ignore its _run_suites implementation since we don't handle it gracefully.
      # If we don't do this #partition is called on the iterator and all suites
      # distributed immediately, instead of picked up as workers are available.
      suites.map { |suite| _run_suite suite, type }
    else
      super
    end
  end

  def _run_anything(*)
    ret = super
    output.puts
    ret
  end

  def _run_suite(suite, type)
    output.print '    '
    output.print suite
    output.print ': '

    start = Time.now
    ret = super
    diff = Time.now - start

    output.puts('  <%.3f>' % diff)
    ret
  end

  self.runner = new
  self.output = StringIO.new
end

class MiniTest::Unit::TestCase
  class << self
    attr_accessor :test_suites

    def original_test_suites
      @@test_suites.keys.reject { |s| s.test_methods.empty? }
    end
  end

  def failure_count
    failures.length
  end
end

module TestQueue
  class Runner
    class Minitest < Runner
      def initialize
        if ::MiniTest::Unit::TestCase.original_test_suites.any?
          raise 'Do not `require` test files. Pass them via ARGV instead and they will be required as needed.'
        end

        super(TestFramework::Minitest.new)
      end

      def run_worker(iterator)
        ::MiniTest::Unit::TestCase.test_suites = iterator
        ::MiniTest::Unit.new.run
      end
    end
    MiniTest = Minitest # For compatibility with test-queue 0.7.0 and earlier.
  end

  class TestFramework
    class Minitest < TestFramework
      def all_suite_files
        ARGV
      end

      def suites_from_file(path)
        ::MiniTest::Unit::TestCase.reset
        require File.absolute_path(path)
        ::MiniTest::Unit::TestCase.original_test_suites.map { |suite|
          [suite.name, suite]
        }
      end
    end
    MiniTest = Minitest # For compatibility with test-queue 0.7.0 and earlier.
  end
end
