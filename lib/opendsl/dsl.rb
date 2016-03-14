require 'opendsl/node_builder'
require 'opendsl/node'

class Dsl
  attr_reader :root, :args

  def initialize(*args, &block)
    tree = NodeBuilder.new('root')
    tree.instance_exec(&block)
    @args = args
    @root = Node.new(tree)
  end

  def method_missing(method_symbol, *args, &block)
    @root.respond_to?(method_symbol) ? @root.send(method_symbol, args) : super
  end
end
