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

  def method_missing(method_symbol, *args, &_block)
    result = @children.select { |child| child.name == method_symbol.to_s.gsub('=', '').to_sym }
    if method_symbol.to_s.end_with?('=')
      if result.count > 0
        node = result.first
        node.args = args
      else
        @children << Node.new(method_symbol.to_s.gsub('=', '').to_sym, args)
      end
    else
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
  end

  def respond_to?(_method_symbol, _include_private = false)
    # TODO
    true
  end
end
