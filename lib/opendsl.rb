require 'opendsl/version'
require 'opendsl/node_builder'
require 'opendsl/node'

module Opendsl
  def self.define(*_args, &block)
    raise(ArgumentError, 'A block is mandatory.') unless block_given?
    tree = NodeBuilder.new('root')
    tree.instance_exec(&block)
    Node.new(tree.name, tree.args, tree.children)
  end
end
