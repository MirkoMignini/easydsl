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
  end

  context 'Assignments' do
    context 'Static' do
      let(:static_dsl) do
        Easydsl.define do
          title 'hello'

          menu do
            position :top
            config do
              layer :block
            end
            item 'item 1'
            item 'item 2'
          end
        end
      end

      it 'set and get string value to an existing root property' do
        string_value = 'test title'
        expect(static_dsl.title = string_value).to eq(string_value)
        expect(static_dsl.title).to eq(string_value)
      end

      it 'set and get array value to an existing root property' do
        array_value = [1, 2, 3]
        expect(static_dsl.title = array_value).to eq(array_value)
        expect(static_dsl.title).to eq(array_value)
      end

      it 'set and get hash value to an existing root property' do
        hash_value = { test1: '1', test2: '2' }
        expect(static_dsl.title = hash_value).to eq(hash_value)
        expect(static_dsl.title).to eq(hash_value)
      end

      it 'set and get symbol to an existing root property' do
        symbol_value = :test
        expect(static_dsl.title = symbol_value).to eq(symbol_value)
        expect(static_dsl.title).to eq(symbol_value)
      end

      it 'set and get symbol to an existing nested property' do
        symbol_value = :left
        expect(static_dsl.menu.position = symbol_value).to eq(symbol_value)
        expect(static_dsl.menu.position).to eq(symbol_value)
      end

      it 'set and get symbol to an existing double nested property' do
        symbol_value = :transparent
        expect(static_dsl.menu.config.layer = symbol_value).to eq(symbol_value)
        expect(static_dsl.menu.config.layer).to eq(symbol_value)
      end

      it 'set a block to an existing property' do
        expect do
          static_dsl.menu do
            item 'item 3'
          end
        end.to change {
          static_dsl.menu.items.count
        }.from(2).to(3)
      end

      it 'set a block to an existing property with custom code' do
        expect do
          static_dsl.menu do
            (1..10).each do |index|
              item "item #{index}"
            end
          end
        end.to change {
          static_dsl.menu.items.count
        }.by(10)
      end
    end

    context 'Dynamic' do
      it 'set and get string to a not existing root property' do
        expect(dsl.root_value = 'test value').to eq('test value')
        expect(dsl.root_value).to eq('test value')
      end

      it 'set and get string to a not existing nested property' do
        expect(dsl.config.custom_value = 'test value').to eq('test value')
        expect(dsl.config.custom_value).to eq('test value')
      end

      it 'set a block to a not existing property' do
        dsl.config_extra do
          extra 'extra item'
        end
        expect(dsl.config_extra.extra).to eq('extra item')
      end
    end
  end
end
