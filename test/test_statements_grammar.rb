require_relative 'test_helper'

class TestNewlineSep < MiniTest::Unit::TestCase
  class Statements < Kramer::Grammar
    rule(:ws) {
      term(/\s/).any
    }

    # Helper for a terminator + whitespace
    helper(:t) do |term|
      term(term) + ws
    end

    rule(:int) {
      t(/[0-9]+/) ^ :int
    }

    rule(:ident) {
      t(/[a-z]+/)
    }

    rule(:assign) {
      (ident/:var + t("=") + expr/:expr) ^ :assign
    }

    rule(:expr) {
      int | assign | subexpr
    }

    rule(:subexpr) {
      t("(") + exprs + t(")") 
    }

    rule(:sep) {
      # Consume as many as ; and \n followed by (other) whitespace.
      (term(/[;\n]+/) + ws).many
    }

    rule(:exprs) {
      ws |
      expr.
      infix { |l, r|
        l/:left + sep + r/:right ^ :exprs
      }
    }

    root :exprs
  end

  def parse(str)
    Statements.new(str)
  end

  def unambig?(thing)
    case thing
    when String, nil
      true
    when Kramer::Slice
      unambig?(thing.value)
    when Kramer::Node
      unambig?(thing.value)
    when Kramer::Multiple
      false
    when Hash
      thing.all? { |k, s| unambig?(s.value) }
    else
      raise "Unknown node: #{thing.class}"
    end
  end

  def assert_unambig(str)
    p = parse(str)
    assert p.success?
    assert_equal 1, p.results.size
    assert unambig?(p.result)
  end

  def test_unambig
    assert_unambig "a=1"
    assert_unambig "a=(1;1)"
    assert_unambig "a=(1; \n\n2)"
    assert_unambig "a=(1 \n 2)\n"
    assert_unambig "a=(1\n\n2)\n"
    assert_unambig " "
  end
end

