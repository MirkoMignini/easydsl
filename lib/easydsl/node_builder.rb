module Easydsl
  class NodeBuilder
    attr_reader :name, :args

    def children
      @children ||= []
    end

    def initialize(name, *args)
      @name = name
      @args = args
    end

    def method_missing(method_symbol, *args, &block)
      child = NodeBuilder.new(method_symbol, *args)
      children.push(child)
      child.instance_exec(&block) if block_given?
    end
  end
end
