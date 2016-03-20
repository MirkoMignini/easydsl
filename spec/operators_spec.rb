require 'spec_helper'

describe 'Operators' do
  context 'Operator =' do
    context 'Existing property' do
      let(:dsl) do
        Easydsl.define do
          title 'hello'
          item 'item 1'

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
        expect(dsl.title = string_value).to eq(string_value)
        expect(dsl.title).to eq(string_value)
      end

      it 'set and get array value to an existing root property' do
        array_value = [1, 2, 3]
        expect(dsl.title = array_value).to eq(array_value)
        expect(dsl.title).to eq(array_value)
      end

      it 'set and get hash value to an existing root property' do
        hash_value = { test1: '1', test2: '2' }
        expect(dsl.title = hash_value).to eq(hash_value)
        expect(dsl.title).to eq(hash_value)
      end

      it 'set and get symbol to an existing root property' do
        symbol_value = :test
        expect(dsl.title = symbol_value).to eq(symbol_value)
        expect(dsl.title).to eq(symbol_value)
      end

      it 'set and get symbol to an existing nested property' do
        symbol_value = :left
        expect(dsl.menu.position = symbol_value).to eq(symbol_value)
        expect(dsl.menu.position).to eq(symbol_value)
      end

      it 'set and get symbol to an existing double nested property' do
        symbol_value = :transparent
        expect(dsl.menu.config.layer = symbol_value).to eq(symbol_value)
        expect(dsl.menu.config.layer).to eq(symbol_value)
      end

      it 'set a block to root' do
        expect do
          dsl.add_block do
            item 'item 3'
          end
        end.to change {
          dsl.items.count
        }.from(1).to(2)
      end

      it 'set a block to an existing property' do
        expect do
          dsl.menu do
            item 'item 3'
          end
        end.to change {
          dsl.menu.items.count
        }.from(2).to(3)
      end

      it 'set a block to an existing property with custom code' do
        expect do
          dsl.menu do
            (1..10).each do |index|
              item "item #{index}"
            end
          end
        end.to change {
          dsl.menu.items.count
        }.by(10)
      end
    end

    context 'Not existing property' do
      let(:dsl) do
        Easydsl.define do
          config do
          end
        end
      end

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
          item
          item
        end
        expect(dsl.config_extra.extra).to eq('extra item')
        expect(dsl.config_extra.items.count).to eq(2)
      end
    end
  end

  context 'Operator ?' do
    let(:dsl) do
      Easydsl.define do
        title 'hello'
        item
        item
      end
    end

    it 'returns true for member that exist' do
      expect(dsl.title?).to eq(true)
    end

    it 'returns false for member that not exist' do
      expect(dsl.not_exist?).to eq(false)
    end

    it 'returns true for array that exist' do
      expect(dsl.items?).to eq(true)
    end

    it 'returns true for array that not exist' do
      expect(dsl.things?).to eq(false)
    end
  end
end
