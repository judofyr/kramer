require 'kramer'

module Kramer
  module DSL
    def self.load(filename)
      parse(File.read(filename))
    end

    def self.parse(str)
      res = nil
      res = Grammar.new(str)
      raise res.failure_message unless res.success?
      g = Class.new(Kramer::Grammar)
      class << g
        attr_accessor :current, :fix, :dir, :dirn
        def rules; @rules ||= {} end
      end
      compile(res.result.val, g)
      g
    end

    def self.compile(node, g)
      val = node.value
      case node.name
      when :defs
        compile(val[:left].val, g)
        compile(val[:right].val, g)
      when :rule
        name = val[:name].val
        g.current = name
        parser = compile(val[:rule].val, g)
        g.rules[name] = parser
      when :modifier
        parser = compile(val[:rule].val, g)
        case val[:type].val
        when "?"
          parser.maybe
        when "+"
          parser.many
        when "*"
          parser.any
        end
      when :chars
        g.term(/[#{val[:content].val}]/)
      when :concat
        compile(val[:left].val, g) + compile(val[:right].val, g)
      when :union
        compile(val[:left].val, g) | compile(val[:right].val, g)
      when :choice
        base = compile(val[:left].val, g)
        top = nil

        left = right = nil
        g.fix = {
          :left  => g.parser(g::Rule) { top },
          :right => g.parser(g::Rule) { base },
        }
        res = compile(val[:right].val, g)
        g.fix = nil
        top = g.parser(g::Rule) { res | base }
      when :fix
        if val[:prec].val.value[:dir].val == "left"
          g.dir = :left
          g.dirn = :right
        else
          g.dir = :right
          g.dirn = :left
        end

        compile(val[:rule].val, g)
      when :node
        compile(val[:rule].val, g) ^ val[:name].val.to_sym
      when :capture
        compile(val[:rule].val, g) / val[:name].val.to_sym
      when :ruleref
        name = val
        if f = g.fix and name == g.current
          res = f[g.dir]
          g.dir = g.dirn
          res
        else
          g.parser(g::Rule) { g.rules[name] or raise "Missing: #{name}" }
        end
      when :string
        g.term(val[:content].val)
      when :root
        g.rule(:root) { g.rules[val[:name].val] }
      else
        raise "Unknown: #{node.name}"
      end
    end

    class Grammar < Kramer::Grammar
      root :defs

      rule(:ws) { term(/\s/).many | ws? + comment }
      rule(:ws?) { ws.maybe }
      rule(:comment) {
        term("#") + term(/[^\n]+/) + ws?
      }

      rule(:rule_name) {
        term(/[A-Z][A-Za-z]*/)
      }

      rule(:ident) {
        term(/[a-z][a-zA-Z_]*/)
      }

      rule(:sep) {
        (term(/\n+/) + ws?).many
      }

      rule(:root_) {
        term("root") + ws + rule_name/:name + ws? ^ :root
      }

      rule(:defs) {
        (lhs | root_).
        infix { |l, r|
          l/:left + sep + r/:right ^ :defs
        }
      }

      rule(:lhs) {
        rule_name/:name + ws? + term("<-") + ws? + rhs/:rule ^ :rule
      }

      rule(:rhs) {
        (ruleref | string | chars).
        infix { |l, r|
          l/:rule + term(":") + ident/:name + ws? ^ :capture
        }.
        infix { |l, r|
          l/:rule + term(/[?+*]/)/:type + ws? ^ :modifier
        }.
        infix { |l, r|
          l/:left + term(/ +/) + r/:right ^ :concat
        }.
        infix { |l, r|
          l/:rule + term("@") + ident/:name + ws? ^ :node
        }.
        infix { |l, r|
          l/:rule + prec/:prec ^ :fix
        }.
        infix { |l, r|
          l/:left + term("|") + ws? + r/:right ^ :union
        }.
        infix { |l, r|
          l/:left + term(">") + ws? + r/:right ^ :choice
        }
      }

      rule(:string) {
        term('"') +
          term(/[^"]+/)/:content +
        term('"') + ws? ^ :string
      }

      rule(:ruleref) {
        (rule_name ^ :ruleref) + ws?
      }

      rule(:chars) {
        term('[') + term(/[^\]]+/)/:content + term(']') + ws? ^ :chars
      }

      rule(:prec) {
        term("%") + term(/left|right/)/:dir + ws? ^ :prec
      }
    end
  end
end

