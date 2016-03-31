require 'spec_helper'
require 'pp'

describe Easydsl do
  let(:dsl) do
    Easydsl.define do
      config do
        title 'test title'
        extra short_description: 'short desc', long_description: 'long desc'
        template do
          layout :standard
          color :red
        end
      end

      class Post
      end

      resource Post do
        permit_params [:title, :description]
      end

      menu 'simpsons', label: 'test' do
        item 'homer'
        item 'marge'
        item 'bart'
        item 'lisa'
        item 'maggie'
        item
        item
      end

      routing action: 'test', model: Post

      navbar position: :top, behaviour: :standard do
        item label: 'Dashboard'
        item label: 'Settings'
        item label: 'Profile'
        item label: 'Help'

        procs my_proc: proc { |text = 'hello'| text },
              my_lambda: ->(text = 'hello') { text }
      end

      navbar position: :left do
      end
    end
  end

  it 'has a version number' do
    expect(Easydsl::VERSION).not_to be nil
  end

  context 'Initialization' do
    it 'initialize dsl' do
      expect(dsl).not_to be_nil
      expect(dsl).to be_kind_of(Easydsl::Node)
    end

    it 'does not initialize dsl if no block given' do
      expect { Easydsl.define }.to raise_error(ArgumentError)
    end
  end

  context 'Members' do
    it 'returns nil if object does not exist' do
      expect(dsl.not_exist).to be_nil
    end

    it 'returns a node by name' do
      expect(dsl.config).to be_kind_of(Easydsl::Node)
    end

    it 'returns the value of a root member' do
      expect(dsl.config.title).to eq('test title')
    end

    it 'returns the value of a nested member' do
      expect(dsl.config.template.layout).to eq(:standard)
    end

    it 'returns the value of a nested member hash' do
      expect(dsl.config.extra[:long_description]).to eq('long desc')
    end

    it 'returns the first element if multiple present' do
      expect(dsl.navbar).not_to be_nil
    end

    it 'returns the value if called directly' do
      node = dsl.config.title
      expect(node).to eq('test title')
      expect(dsl.config.title).to eq('test title')
    end
  end

  context 'Members override' do
    let(:dsl) do
      Easydsl.define do
        items 'plural'
        item 'singular 1'
        item 'singular 2'
      end
    end

    it 'returns items (plural) instead of items array' do
      expect(dsl.items).to eq('plural')
    end

    it 'returns first item' do
      expect(dsl.item).to eq('singular 1')
    end
  end

  context 'Collections' do
    it 'returns a collection' do
      expect(dsl.navbars).not_to be_nil
      expect(dsl.navbars).to be_kind_of(Easydsl::NodeArray)
    end

    it 'responds to array methods' do
      expect(dsl.navbars.count).to eq(2)
      expect(dsl.resources.count).to eq(1)
      expect(dsl.navbars[0]).to be_kind_of(Easydsl::Node)
    end

    it 'returns a nested collection' do
      expect(dsl.menu.items).not_to be_nil
      expect(dsl.menu.items).to be_kind_of(Easydsl::NodeArray)
    end

    it 'selects a collection based on a filter' do
      navbars = dsl.navbars.select { |navbar| navbar[:position] == :left }
      expect(navbars.count).to eq(1)
      navbars = dsl.navbars.select { |navbar| navbar[:position] == :right }
      expect(navbars.count).to eq(0)
      navbars = dsl.navbars.select { |navbar| navbar[:position] == :top }
      expect(navbars.count).to eq(1)
    end

    it 'removes an item' do
      expect { dsl.menu.items.delete_at(0) }.to change { dsl.menu.items.count }.by(-1)
    end
  end

  context 'Node' do
    it 'returns a parameter by key' do
      expect(dsl.routing[:action]).to eq('test')
      expect(dsl.routing[:model]).to be(Post)
    end

    it 'calls a lambda in a parameter' do
      expect(dsl.navbar.procs[:my_lambda].call('mytext')).to eq('mytext')
    end

    it 'calls a proc in a parameter' do
      expect(dsl.navbar.procs[:my_proc].call('mytext')).to eq('mytext')
    end

    it 'returns nil parent if root node' do
      expect(dsl.parent).to be_nil
    end

    it 'returns root node parent if root nested node' do
      expect(dsl.navbar.parent).to eq(dsl)
    end
  end

  context 'Index' do
    let(:dsl) do
      Easydsl.define do
        item '1'
        item '2'
        hello '1'
        hello '2'
      end
    end

    it 'returns all children' do
      expect(dsl.all_nodes).to be_kind_of(Array)
      expect(dsl.all_nodes[0]).to be_kind_of(Easydsl::Node)
      expect(dsl.all_nodes.count).to eq(4)
    end

    it 'checks if all children are sorted' do
      expect(dsl.all_nodes[0].index).to eq(0)
      expect(dsl.all_nodes[1].index).to eq(1)
      expect(dsl.all_nodes[2].index).to eq(2)
      expect(dsl.all_nodes[3].index).to eq(3)
    end

    it 'returns the max index' do
      expect(dsl.max_index).to eq(3)
    end

    it 'returns the max index when a block is added' do
      expect do
        dsl.add_block do
          item 'item 3'
        end
      end.to change {
        dsl.all_nodes.count
      }.from(4).to(5)
    end
  end
end
