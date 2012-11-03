$LOAD_PATH << File.expand_path('../../lib', __FILE__)
require 'kramer'

class Calc < Kramer::Grammar
  rule(:ws) {
    term(/\s+/).maybe
  }

  helper(:t) { |s, n|
    term(s)/n + ws
  }

  rule(:number) {
    (term(/[0-9]+/) ^ :number) + ws
  }

  rule(:sub) {
    term("(") + expr + term(")")
  }

  rule(:basic) {
    number | sub
  }

  helper(:op) { |l, op, r|
    l/:left + term(op)/:op + ws + r/:right ^ :infix
  }

  rule(:expr) {
    basic.
    infix { |l, r|
      op(r, "**", l)
    }.
    infix { |l, r|
      op(l, "*", r) | op(l, "/", r)
    }.
    infix { |l, r|
      op(l, "+", r) | op(l, "-", r)
    }
  }

  root :expr
end

def run(node)
  val = node.value
  case node.name
  when :infix
    run(val[:left].val).send(val[:op].val, run(val[:right].val))
  when :number
    val.to_i
  else
    raise "Missing: #{node.name}"
  end
end

require 'pp'

def input
  print ">> "
  res = gets and res.chomp
end

while str = input
  c = Calc.new(str)
  if c.success?
    puts "=> #{run(c.result.val)}"
  else
    puts "!> Parse error"
  end
end

