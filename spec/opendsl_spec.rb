require 'spec_helper'
require 'opendsl/dsl'
require 'pp'

describe Opendsl do
  let(:dsl) do
    return Dsl.new do
      config do
        title 'test title'
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

      navbar 'hello', 'hello2', position: :top, behaviour: :standard do
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
    expect(Opendsl::VERSION).not_to be nil
  end

  it 'initialize dsl' do
    expect(dsl).not_to be_nil
  end

  context 'Members' do
    it 'returns nil if object does not exist' do
      expect(dsl.not_exist).to be_nil
    end

    it 'returns an object by name' do
      expect(dsl.config).not_to be_nil
    end

    it 'returns the value of a root member' do
      expect(dsl.config.title).to eq('test title')
    end

    it 'returns the value of a nested member' do
      expect(dsl.config.template.layout).to eq(:standard)
    end

    it 'returns the first element if multiple present' do
      expect(dsl.navbar).not_to be_nil
    end
  end

  context 'Collections' do
    it 'returns a collection' do
      expect(dsl.navbars).not_to be_nil
      expect(dsl.navbars).to be_kind_of(NodeArray)
    end

    it 'responds to array methods' do
      expect(dsl.navbars.count).to eq(2)
      expect(dsl.navbars[0]).to be_kind_of(Node)
    end

    it 'returns a nested collection' do
      expect(dsl.menu.items).not_to be_nil
      expect(dsl.menu.items).to be_kind_of(NodeArray)
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

  context 'Collection queries' do
    context 'find' do
      it 'responds to find' do
        expect(dsl.navbars).to respond_to(:find)
      end

      it 'returns the right object' do
        expect(dsl.navbars.find(position: :left)).to be(dsl.navbars.last)
      end

      it 'returns nil if nothing found' do
        expect(dsl.navbars.find(position: :right)).to be_nil
      end
    end

    context 'where' do
      it 'responds to where' do
        expect(dsl.navbars).to respond_to(:where)
      end

      it 'raise exception if argument is not hash' do
        expect { dsl.navbars.where('hello') }.to raise_error(ArgumentError)
      end

      it 'returns the array filtered' do
        expect(dsl.navbars.where(position: :left).first).to be(dsl.navbars.last)
      end

      it 'returns empty array if nothing found' do
        expect(dsl.navbars.where(position: :right)).to eq([])
      end
    end
  end

  context 'Assignments' do
    context 'Static' do
      let(:static_dsl) do
        return Dsl.new do
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
        expect {
          static_dsl.menu do
            item 'item 3'
          end
        }.to change {
          static_dsl.menu.items.count
        }.by(1)
      end
    end

    context 'Dynamic' do
      it 'set and get string to a not existing root property' do
        expect(dsl.root_value = 'test value').to eq('test value')
        expect(dsl.root_value).to eq('test value')
      end
    end
  end
end
