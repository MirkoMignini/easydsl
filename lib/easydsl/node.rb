require 'active_support/inflector'
require 'easydsl/node_array'

module Easydsl
  class Node
    attr_reader :name, :index, :parent, :singleton
    attr_accessor :args

    def initialize(name, args, index, parent, node_builders = [])
      @name = name.to_s.chomp('!').to_sym
      @singleton = name[-1] == '!'
      @args = args
      @index = index
      @parent = parent
      node_builders.each_with_index do |item, i|
        add_child(item.name, item.args, i, self, item.nodes)
      end
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

    def define(&block)
      add_block(&block)
    end

    protected

    def add_hierarchy(to, tree, base_index)
      tree.each_with_index do |item, index|
        to.add_child(item.name, item.args, base_index + index, to, item.nodes)
      end
    end

    def add_block(&block)
      tree = NodeBuilder.new('tree')
      tree.instance_exec(&block)
      add_hierarchy(self, tree.nodes, max_index)
    end

    def add_child(name, args, index, parent, node_builders = [])
      node = handle_singleton(name, args, node_builders)
      return node unless node.nil?
      node = Node.new(name, args, index, parent, node_builders)
      nodes[node.name] << node
      node
    end

    def handle_singleton(name, args, node_builders = [])
      return nil unless nodes.key?(name)
      node = nodes[name].first
      return nil if node.nil? || node.singleton == false
      node.args = args
      add_hierarchy(node, node_builders, node.max_index)
      nodes[name].first
    end

    def clean_method_symbol(method_symbol)
      method_symbol.to_s.gsub(/[=?]/, '').to_sym
    end

    def singular_method_symbol(method_symbol)
      method_symbol.to_s.singularize.to_sym
    end

    def handle_block(method_symbol, *args, &block)
      collection = nodes[method_symbol]
      child = if collection.count > 0
        collection.first
      else
        add_child(method_symbol, args, max_index, self)
      end
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
      if collection.count > 0
        collection.first.args = args
      else
        add_child(method_symbol, args, max_index, self)
      end
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
