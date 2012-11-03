require 'kramer/parsers'

module Kramer
  # Implementation of "Memoization in Top-Down Parsing" by Mark Johnson, 1995
  module Johnson95
    include Parsers

    def parse
      t = Trampoline.new
      t.parse(@parser, @position) do |res|
        if res.done?
          @results << res
        elsif res.failed?
          @failures << res
        end
      end
      t.step while t.next?
    end

    class ParserContext
      attr_reader :conts, :results

      # Fast and simple Set implementation
      class SimpleSet
        def initialize
          @hash = {}
        end

        def <<(v)
          @hash[v] = 1
        end

        def include?(v)
          @hash.has_key?(v)
        end

        def each(&blk)
          @hash.keys.each(&blk)
        end
      end

      def empty?
        @conts.empty?
      end

      def initialize
        @conts = []
        @results = SimpleSet.new
      end
    end

    class Trampoline
      def initialize
        @stack = []
        @table = Hash.new { |h, k| h[k] = {} }
      end

      def next?
        !@stack.empty?
      end

      def step
        obj, args, blk = @stack.pop
        obj.call(*args, &blk)
      end

      def push(obj, *args, &blk)
        @stack << [obj, args, blk]
      end

      def parse(fn, pos, &c)
        memo = @table[pos.index]
        ctx = memo[fn] ||= ParserContext.new

        # This is the first time we're invoking this parser
        if ctx.empty?

          # Add this continuation
          ctx.conts << c

          # Call the actual parser
          push(fn, self, pos) do |res|
            # We don't care about duplicate responses
            if !ctx.results.include?(res)
              ctx.results << res

              # Invoke all continues (including ourself)
              ctx.conts.each { |cc| cc.call(res) }
            end
          end

        # This parser has been setup earlier
        else
          # Add ourself. The call to the actual parser above will then
          # invoke this continuation.
          ctx.conts << c

          # Invoke previous results
          ctx.results.each { |res| c.call(res) }
        end
      end

      hash = Hash

      # Poor man's pattern matching
      COMBINERS = {
        [String, String] => :+,

        [hash, hash]      => proc { |a, b| a.merge(b) },
        [hash, String]    => proc { |a, _| a },
        [String, hash]    => proc { |_, b| b },

        [NilClass, :any] => proc { |_, b| b },
        [:any, NilClass] => proc { |a, _| a },
      }

      # Compute wildcards:
      COMBINERS.default_proc = lambda do |h, k|
        c1, c2 = k

        variations = [
          [c1, c2],
          [c1, :any],
          [:any, c2],
        ]

        res = nil

        h.each do |var, r|
          if variations.include?(var)
            res = r
            break
          end
        end

        h[k] = res
      end

      def cache
        @cache ||= {}
      end

      def combine_value(v1, v2)
        c = COMBINERS[[v1.class, v2.class]]
        #p [v1.class, v2.class]
        raise "Can't combine: #{v1.inspect} - #{v2.inspect}" if c.nil?
        c.to_proc.call(v1, v2)
      end
    end

    class Terminal < Terminal
      def parse(t, pos)
        if length = matches?(pos)
          yield pos.consume(length)
        elsif !pos.done?
          yield pos.fail("Expected: #{@match}")
        end
      end
    end

    class Union < Union
      def parse(t, pos, &c)
        t.parse(left, pos, &c)
        t.parse(right, pos, &c)
      end
    end

    class Concat < Concat
      def parse(t, pos, &c)
        cache = t.cache

        t.parse(left, pos) do |res1|
          next yield res1 if res1.failed?

          t.parse(right, res1.position) do |res2|
            next yield res2 if res2.failed?
            next yield res1 if res2.empty?
            next yield res2 if res1.empty?

            spans = [:spans, self, res1.start, res2.stop]
            val = t.combine_value(res1.value, res2.value)

            if res = cache[spans]
              if val && res.value
                res.value = Multiple.new(res.value, val)
              else
                res.value ||= val
              end
              
              yield res
            else
              res = Slice.new(res1.string, res1.start, res2.stop, val)
              cache[spans] = res
              yield res
            end
          end
        end
      end
    end
    
    class Noder < Noder
      def parse(t, pos)
        t.parse(parser, pos) do |res|
          if res.failed?
            yield res
          else
            yield res.wrap(Node.new(name, res))
          end
        end
      end
    end

    class Picker < Picker
      def parse(t, pos)
        t.parse(parser, pos) do |res|
          if res.failed?
            yield res
          else
            yield res.wrap(name => res)
          end
        end
      end
    end

    class Epsilon < Epsilon
      def parse(t, pos)
        yield pos.consume(0)
      end
    end
  end
end

