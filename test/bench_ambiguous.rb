require_relative 'test_helper'

class Benchmark < MiniTest::Unit::TestCase
  def grammar
    Class.new(Kramer::Grammar) do
      root :expr

      rule(:number) {
        term(/[0-9]+/) ^ :number
      }

      rule(:expr) {
        number |
        expr/:left + term("+") + expr/:right ^ :plus
      }
    end
  end

  def self.bench_range
    bench_linear 30, 70
  end

  def assert_performance_cubic(threshold, &blk)
    power = validation_for_fit(:power, threshold)

    validation = proc do |range, times|
      a, b, rr = power.call(range, times)
      assert_operator b, :<, 3
      [a, b, rr]
    end

    assert_performance(validation, &blk)
  end

  def test_recognize_ok
    assert_performance_cubic 0.95 do |n|
      str = "1+"*n+"1"
      p = grammar.new(str)
      assert p.success?
    end
  end

  def test_recognize_no
    assert_performance_cubic 0.95 do |n|
      str = "1+"*n+"+1"
      p = grammar.new(str)
      refute p.success?
    end
  end
end

