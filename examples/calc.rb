$LOAD_PATH << File.expand_path('../../lib', __FILE__)
require 'kramer/dsl'

Calc = Kramer::DSL.parse <<-'end'
root Expr

WS     <- [\s]+
Number <- [0-9]+ @number
Sub    <- "(" WS?  Expr  ")"
Expr   <- Number WS?
        | Sub WS?
        > Expr:left "**":type WS? Expr:right  @op %right
        > Expr:left "*":type  WS? Expr:right  @op  %left
        | Expr:left "/":type  WS? Expr:right  @op  %left
        > Expr:left "+":type  WS? Expr:right  @op  %left
        | Expr:left "-":type  WS? Expr:right  @op  %left
end

def run(node)
  val = node.value
  case node.name
  when :op
    run(val[:left].val).send(val[:type].val, run(val[:right].val))
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
    puts c.failure_message
  end
end

