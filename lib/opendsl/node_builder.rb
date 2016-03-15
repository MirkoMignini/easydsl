class NodeBuilder
  attr_reader :children, :name, :args

  def initialize(name, *args)
    @name = name
    @args = args
    @children = []
  end

  def method_missing(method_symbol, *args, &block)
    child = NodeBuilder.new(method_symbol, *args)
    @children.push(child)
    child.instance_exec(&block) if block_given?
  end
end
