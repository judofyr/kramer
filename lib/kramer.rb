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
  end
end

