require 'active_support/inflector'
require 'opendsl/node_array'

class Node
  attr_reader :name
  attr_accessor :args

  def initialize(name, args, node_builders = [])
    @name = name
    @args = args
    node_builders.each { |child| add_child(child.name, child.args, child.children) }
  end

  def children
    @children ||= Hash.new { |h, k| h[k] = NodeArray.new }
  end

  def add_child(name, args, node_builders = [])
    node = Node.new(name, args, node_builders)
    children[node.name] << node
    node
  end

  def link_block(&block)
    tree = NodeBuilder.new('tree')
    tree.instance_exec(&block)
    tree.children.each { |child| add_child(child.name, child.args, child.children) }
  end

  def clean_method_symbol(method_symbol)
    method_symbol.to_s.delete('=').to_sym
  end

  def singular_method_symbol(method_symbol)
    method_symbol.to_s.singularize.to_sym
  end

  def handle_block(method_symbol, *args, &block)
    collection = children[method_symbol]
    child = collection.count > 0 ? collection.first : add_child(method_symbol, args)
    child.link_block(&block)
  end

  def handle_brackets(_method_symbol, *args)
    @args.first[args.first]
  end

  def handle_assignment(method_symbol, *args)
    collection = children[method_symbol]
    collection.count > 0 ? collection.first.args = args : add_child(method_symbol, args)
  end

  def handle_node(method_symbol, *_args)
    return children[method_symbol].first.value_or_self if children[method_symbol].count > 0
    singular = singular_method_symbol(method_symbol)
    return children[singular] if method_symbol != singular
    nil
  end

  def value_or_self
    return @args.first if children.count == 0 && @args.count == 1 && @args.first.class != Node
    self
  end

  def method_missing(method_symbol, *args, &block)
    if block_given?
      handle_block(method_symbol, *args, &block)
    elsif method_symbol.to_s == '[]'
      handle_brackets(method_symbol, *args, &block)
    elsif method_symbol.to_s.end_with?('=')
      handle_assignment(clean_method_symbol(method_symbol), *args, &block)
    else
      handle_node(method_symbol, *args, &block)
    end
  end
end
