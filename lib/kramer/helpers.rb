module Kramer
  class Position
    attr_reader :string, :index

    def initialize(string, index)
      @string = string
      @index = index
    end

    def position_with?(str)
      string[index, str.length] == str
    end

    def done?
      index == string.size
    end

    def consume(length, value = nil)
      Slice.new(string, index, index + length, value)
    end

    def fail(str)
      consume(0, Failure.new(str))
    end
  end

  class Slice
    attr_reader :string, :start, :stop
    attr_accessor :value

    def initialize(string, start, stop, value = nil)
      @string = string
      @start = start
      @stop = stop
      @value = value
    end

    def position
      @position ||= Position.new(string, stop)
    end

    def submatch
      @submatch ||= string[start...stop]
    end

    def empty?
      start == stop
    end

    def done?
      stop == string.size
    end

    def failed?
      value.is_a?(Failure)
    end

    def wrap(value)
      Slice.new(string, start, stop, value)
    end

    def inspect
      "#<Slice #{start}:#{stop} #{val.inspect}>"
    end

    def val
      value || submatch
    end

    def pretty_print(q)
      q.group(1, "#<Slice #{start}:#{stop}", '>') {
        q.breakable
        q.group(1) {
          q.pp val
        }
      }
    end
  end

  class Failure
    def initialize(message)
      @message = message
    end
  end

  class Node < Struct.new(:name, :slice)
    def value
      slice.value || slice.submatch
    end

    def inspect
      "#<Node #{name} #{slice.inspect}>"
    end

    def pretty_print(q)
      q.group(1, "#<Node #{name}", '>') {
        q.breakable
        q.group(1) {
          q.pp slice
        }
      }
    end
  end

  class Multiple < Struct.new(:left, :right)
  end
end

