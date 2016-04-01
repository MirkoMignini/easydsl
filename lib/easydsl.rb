require 'easydsl/version'
require 'easydsl/node_builder'
require 'easydsl/node'

module Easydsl
  def self.define(*_args, &block)
    raise(ArgumentError, 'A block is mandatory.') unless block_given?
    tree = NodeBuilder.new('root')
    tree.instance_exec(&block)
    Node.new(tree.get_name, tree.get_args, 0, nil, tree.get_nodes)
  end
end
