require 'hamster'
require 'kramer/johnson95'
require 'kramer/helpers'

module Kramer
  class Grammar
    include Johnson95

    def self.root(name = nil)
      if name
        @root = name
      else
        send(@root)
      end
    end

    # Creates a parser with a corrct grammar pointer
    def self.parser(klass, *args, &blk)
      p = klass.new(*args, &blk)
      p.grammar = self
      p
    end

    def self.rule(name, &blk)
      r = parser(Rule, &blk)
      define_singleton_method(name) { r }
    end

    def self.helper(name, &blk)
      define_singleton_method(name, &blk)
    end

    def self.eps
      @eps ||= parser(Epsilon)
    end

    def self.term(str)
      parser(Terminal, str)
    end

    attr_reader :string, :results, :failures

    def initialize(string)
      @string = string
      @position = Position.new(@string, 0)
      @parser = self.class.root
      @results = []
      @failures = []
      parse
    end

    def success?
      !@results.empty?
    end

    def result
      @results.first
    end

    def failure_message
      start = nil
      fails = []
      @failures.sort_by { |x| -x.start }.each do |f|
        start ||= f.start
        break if f.start != start
        fails << f.value.message
      end
      sub = @string[0, start]
      lineno = sub.count("\n") + 1
      last_line = (sub.rindex("\n") || -1) + 1
      col = start - last_line

      rest = @string[last_line..-1].sub(/\n.*\Z/m, '')
      spaces = " " * col
      msg = "Expected one of: #{fails.map(&:inspect).join('  ')}"
      "Parse error at line #{lineno}\n  #{rest}\n  #{spaces}^\n#{msg}"
    end
  end
end

