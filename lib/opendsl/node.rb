require 'active_support/inflector'
require 'opendsl/node_array'

class Node
  attr_reader :children, :name, :args

  def initialize(node_builder)
    @name = node_builder.name
    @args = node_builder.args
    @children = []
    node_builder.children.each do |child|
      @children << Node.new(child)
    end
  end

  def method_missing(method_symbol, *_args, &_block)
    result = @children.select { |child| child.name == method_symbol }
    if result.count > 0
      node = result.first
      if node.children.count == 0 && node.args.count == 1 && node.args.first.class != Node
        return node.args.first
      end
      return node
    end

    singular = method_symbol.to_s.singularize
    if singular != method_symbol.to_s
      return NodeArray.new(@children.select { |child| child.name == singular.to_sym })
    end

    nil
  end

  def respond_to?(_method_symbol, _include_private = false)
    # TODO
    true
  end
end
