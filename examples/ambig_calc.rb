$LOAD_PATH << File.expand_path('../../lib', __FILE__)
require 'kramer'

class Calc < Kramer::Grammar
  root :expr

  rule(:number) {
    term(/[0-9]+/) ^ :number
  }

  rule(:expr) {
    number |
    expr/:left + term("+") + expr/:right ^ :plus
  }
end

require 'pp'
c = Calc.new("1+2+3+4")
pp c.result


