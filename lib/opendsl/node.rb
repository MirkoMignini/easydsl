require 'active_support/inflector'
require 'opendsl/node_array'

class Node
  attr_reader :children, :name
  attr_accessor :args

  def initialize(name, args = nil, children = nil)
    @name = name
    @args = args
    @children = []
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

  def value_or_self
    return @args.first if @children.count == 0 && @args.count == 1 && @args.first.class != Node
    self
  end

  def get_array(method_symbol)
    singular = method_symbol.to_s.singularize
    if singular != method_symbol.to_s
      return NodeArray.new(@children.select { |child| child.name == singular.to_sym })
    end
    nil
  end

  def method_missing(method_symbol, *args, &block)
    result = @children.select { |child| child.name == method_symbol.to_s.delete('=').to_sym }

    if block_given?
      child = result.count > 0 ? result.first : add_child(method_symbol, *args)
      child.link_block(&block)
    elsif method_symbol.to_s.end_with?('=')
      result.count > 0 ? result.first.args = args : add_child(method_symbol, *args)
    elsif result.count > 0
      result.first.value_or_self
    else
      get_array(method_symbol)
    end
  end

  def respond_to?(_method_symbol, _include_private = false)
    # TODO
    true
  end
end
