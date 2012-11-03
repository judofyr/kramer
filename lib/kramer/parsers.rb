module Kramer
  module Parsers
    # Base 
    class Parser
      attr_accessor :grammar

      # Instantiate a new parser using a grammar's context
      def new(name, *args, &blk)
        parser = grammar.const_get(name)
        grammar.parser(parser, *args, &blk)
      end

      def call(*args, &blk)
        parse(*args, &blk)
      end

      def |(other)
        new(:Union, self, other)
      end

      def +(other)
        new(:Concat, self, other)
      end

      def maybe
        self | new(:Epsilon)
      end

      def many
        more = new(:Rule) { self + more.maybe }
      end

      def any
        many.maybe
      end

      def /(name)
        new(:Picker, self, name)
      end

      def ^(name)
        new(:Noder, self, name)
      end

      def infix
        top = nil
        bottom = self

        rule = new(:Rule) {
          yield top, bottom
        }

        top = new(:Rule) {
          rule | bottom
        }
      end
    end

    class Rule < Parser
      def initialize(&blk)
        @code = blk
      end

      def parser
        @parser ||= @code.call
      end

      def parse(t, pos, &c)
        parser.parse(t, pos, &c)
      end
    end

    class Epsilon < Parser
    end

    class Terminal < Parser
      def initialize(match)
        @match = match
      end

      def matches?(pos)
        case @match
        when String
          @match.size if pos.position_with?(@match)
        when Regexp
          thing = /\A.{#{pos.index}}(#{@match})/m
          $1.size if thing =~ pos.string
        end
      end
    end

    class LeftRight < Parser
      attr_reader :left, :right

      def initialize(left, right)
        @left = left
        @right = right
      end
    end
    
    class Union < LeftRight
    end

    class Concat < LeftRight
    end

    class Noder < Parser
      attr_reader :parser, :name

      def initialize(parser, name)
        @parser = parser
        @name = name
      end
    end

    class Picker < Parser
      attr_reader :parser, :name

      def initialize(parser, name)
        @parser = parser
        @name = name
      end
    end
  end
end

