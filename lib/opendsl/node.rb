require 'active_support/inflector'
require 'opendsl/node_array'

class Node
  attr_reader :children, :name
  attr_accessor :args

  def initialize(name, args = nil, children = nil)
    @name = name
    @args = args
    @children = NodeArray.new
    unless children.nil?
      children.each { |child| @children << Node.new(child.name, child.args, child.children) }
    end
  end

  def link_block(&block)
    tree = NodeBuilder.new('tree')
    tree.instance_exec(&block)
    tree.children.each { |child| @children << Node.new(child.name, child.args, child.children) }
  end

  def add_child(method_symbol, *args)
    child = Node.new(method_symbol.to_s.delete('=').to_sym, args)
    @children << child
    child
  end

  def get_singular_method(method_symbol)
    method_symbol.to_s.singularize.to_sym
  end

  def get_filtered_children(method_symbol)
    @children.select! { |child| child.name == method_symbol.to_s.delete('=').to_sym }
    @children
  end

  def handle_block(method_symbol, *args, &block)
    collection = get_filtered_children(method_symbol)
    child = collection.count > 0 ? collection.first : add_child(method_symbol, *args)
    child.link_block(&block)
  end

  def handle_brackets(_method_symbol, *args)
    @args.first[args.first]
  end

  def handle_assignment(method_symbol, *args)
    collection = get_filtered_children(method_symbol)
    collection.count > 0 ? collection.first.args = args : add_child(method_symbol, *args)
  end

  def handle_node(method_symbol, *_args)
    collection = get_filtered_children(method_symbol)
    if  collection.first.children.count == 0 &&
        collection.first.args.count == 1 &&
        collection.first.args.first.class != Node
      return collection.first.args.first
    end
    collection.first
  end

  def handle_array(method_symbol, *_args)
    return get_filtered_children(method_symbol)
  end

  def method_missing(method_symbol, *args, &block)
    if block_given?
      handle_block(method_symbol, *args, &block)
    elsif method_symbol.to_s == '[]'
      handle_brackets(method_symbol, *args, &block)
    elsif method_symbol.to_s.end_with?('=')
      handle_assignment(method_symbol, *args, &block)
    else
      result = @children.select { |child| child.name == method_symbol.to_s.delete('=').to_sym }
      if result.count > 0
        handle_node(method_symbol, *args, &block)
      else
        singular_method_symbol = get_singular_method(method_symbol)
        if method_symbol != singular_method_symbol
          handle_array(singular_method_symbol, *args, &block)
        else
          #add_child(method_symbol, *args)
          nil
        end
      end
    end
  end
end
