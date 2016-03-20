require 'active_support/inflector'
require 'easydsl/node_array'

module Easydsl
  class Node
    attr_reader :name, :index
    attr_accessor :args

    def initialize(name, args, index, node_builders = [])
      @name = name
      @args = args
      @index = index
      node_builders.each_with_index { |item, i| add_child(item.name, item.args, i, item.nodes) }
    end

    def nodes
      @nodes ||= Hash.new { |h, k| h[k] = NodeArray.new }
    end

    def all_nodes
      all = []
      nodes.each { |k, _v| all += nodes[k] }
      all.sort! { |a, b| a.index <=> b.index }
    end

    def max_index
      all_nodes.map(&:index).max || 0
    end

    def add_block(&block)
      tree = NodeBuilder.new('tree')
      tree.instance_exec(&block)
      base_index = max_index
      tree.nodes.each_with_index do |item, index|
        add_child(item.name, item.args, base_index + index, item.nodes)
      end
    end

    protected

    def add_child(name, args, index = -1, node_builders = [])
      index = max_index if index == -1
      node = Node.new(name, args, index, node_builders)
      nodes[node.name] << node
      node
    end

    def clean_method_symbol(method_symbol)
      method_symbol.to_s.gsub(/[=?]/, '').to_sym
    end

    def singular_method_symbol(method_symbol)
      method_symbol.to_s.singularize.to_sym
    end

    def handle_block(method_symbol, *args, &block)
      collection = nodes[method_symbol]
      child = collection.count > 0 ? collection.first : add_child(method_symbol, args)
      child.add_block(&block)
    end

    def handle_brackets(_method_symbol, *args)
      @args.first[args.first]
    end

    def handle_operators(method_symbol, *args)
      method_symbol_wo = clean_method_symbol(method_symbol)
      case method_symbol[-1]
      when ']' then handle_brackets(method_symbol_wo, *args)
      when '=' then handle_assignment(method_symbol_wo, *args)
      when '?' then handle_question(method_symbol_wo, *args)
      end
    end

    def handle_assignment(method_symbol, *args)
      collection = nodes[method_symbol]
      collection.count > 0 ? collection.first.args = args : add_child(method_symbol, args)
    end

    def handle_question(method_symbol, *_args)
      if nodes[method_symbol].count > 0
        true
      else
        singular = singular_method_symbol(method_symbol)
        method_symbol != singular ? nodes[singular].count > 0 : false
      end
    end

    def handle_node(method_symbol, *_args)
      return nodes[method_symbol].first.value_or_self if nodes[method_symbol].count > 0
      singular = singular_method_symbol(method_symbol)
      return nodes[singular] if method_symbol != singular
      nil
    end

    def value_or_self
      return @args.first if nodes.count == 0 && @args.count == 1 && @args.first.class != Node
      self
    end

    def method_missing(method_symbol, *args, &block)
      return handle_block(method_symbol, *args, &block) if block_given?
      return handle_operators(method_symbol, *args) if method_symbol.to_s.end_with?('=', '?', '[]')
      handle_node(method_symbol, *args, &block)
    end
  end
end
