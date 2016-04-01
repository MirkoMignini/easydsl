module Easydsl
  class NodeBuilder
    def get_nodes
      @nodes ||= []
    end

    def get_name
      @name
    end

    def get_args
      @args
    end

    def initialize(name, *args)
      @name = name
      @args = args
    end

    def method_missing(method_symbol, *args, &block)
      child = NodeBuilder.new(method_symbol, *args)
      get_nodes.push(child)
      child.instance_exec(&block) if block_given?
    end
  end
end
