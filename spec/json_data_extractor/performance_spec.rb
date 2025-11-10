# frozen_string_literal: true

require 'spec_helper'
require 'benchmark'

RSpec.describe 'Performance Optimizations' do
  let(:data) do
    {
      store: {
        book: [
          { category: 'reference', author: 'Nigel Rees', title: 'Sayings of the Century', price: 8.95 },
          { category: 'fiction', author: 'Evelyn Waugh', title: 'Sword of Honour', price: 12.99 },
          { category: 'fiction', author: 'Herman Melville', title: 'Moby Dick', price: 8.99 },
          { category: 'fiction', author: 'J. R. R. Tolkien', title: 'The Lord of the Rings', price: 22.99 }
        ],
        bicycle: { color: 'red', price: 19.95 }
      }
    }
  end

  let(:schema) do
    {
      authors: { path: '$.store.book[*].author', modifier: :downcase },
      titles: '$.store.book[*].title',
      categories: '$..category',
      bicycle_color: '$.store.bicycle.color'
    }
  end

  describe JsonDataExtractor::DirectNavigator do
    it 'supports simple paths' do
      expect(described_class.simple_path?('$.store.book[*].author')).to be true
      expect(described_class.simple_path?('$.store.bicycle.color')).to be true
      expect(described_class.simple_path?('$..category')).to be false # recursive descent
      expect(described_class.simple_path?('$.store.book[?(@.price < 10)]')).to be false # filter
    end

    it 'correctly extracts data from simple paths' do
      navigator = described_class.new('$.store.book[*].author')
      result = navigator.on(data)
      
      expect(result).to eq(['Nigel Rees', 'Evelyn Waugh', 'Herman Melville', 'J. R. R. Tolkien'])
    end

    it 'handles array indexing' do
      navigator = described_class.new('$.store.book[0].author')
      result = navigator.on(data)
      
      expect(result).to eq(['Nigel Rees'])
    end

    it 'handles nested keys' do
      navigator = described_class.new('$.store.bicycle.color')
      result = navigator.on(data)
      
      expect(result).to eq(['red'])
    end
  end

  describe JsonDataExtractor::OptimizedExtractor do
    it 'produces correct results' do
      extractor = described_class.new(schema)
      result = extractor.extract_from(data)

      expect(result[:authors]).to eq(['nigel rees', 'evelyn waugh', 'herman melville', 'j. r. r. tolkien'])
      expect(result[:titles]).to eq([
        'Sayings of the Century',
        'Sword of Honour',
        'Moby Dick',
        'The Lord of the Rings'
      ])
      expect(result[:categories]).to eq(['reference', 'fiction', 'fiction', 'fiction'])
      expect(result[:bicycle_color]).to eq('red')
    end

    it 'handles nested schemas' do
      nested_schema = {
        name: '$.store',
        books: {
          path: '$.store.book[*]',
          type: 'array',
          schema: {
            title: '$.title',
            author: '$.author'
          }
        }
      }

      extractor = described_class.new(nested_schema)
      result = extractor.extract_from(data)

      expect(result[:books]).to be_an(Array)
      expect(result[:books].size).to eq(4)
      expect(result[:books].first).to include(title: 'Sayings of the Century', author: 'Nigel Rees')
    end

    it 'supports custom modifiers' do
      extractor = described_class.new({ name: { path: '$.store.bicycle.color' } })
      extractor.add_modifier(:upcase_it) { |v| v.upcase }

      schema_with_custom = { color: { path: '$.store.bicycle.color', modifier: :upcase_it } }
      result = described_class.new(schema_with_custom, modifiers: extractor.modifiers).extract_from(data)

      expect(result[:color]).to eq('RED')
    end
  end

  describe 'Integration with existing API' do
    it 'works with JsonDataExtractor.new' do
      extractor = JsonDataExtractor.new(data)
      result = extractor.extract(schema)

      expect(result[:authors]).to eq(['nigel rees', 'evelyn waugh', 'herman melville', 'j. r. r. tolkien'])
    end

    it 'works with JsonDataExtractor.with_schema' do
      extractor = JsonDataExtractor.with_schema(schema)
      result = extractor.extract_from(data)

      expect(result[:authors]).to eq(['nigel rees', 'evelyn waugh', 'herman melville', 'j. r. r. tolkien'])
    end
  end

  describe 'Benchmark comparison', :benchmark do
    # Run with: rspec spec/json_data_extractor/performance_spec.rb --tag benchmark

    let(:large_data) do
      {
        store: {
          book: Array.new(100) do |i|
            {
              category: ['reference', 'fiction', 'mystery'].sample,
              author: "Author #{i}",
              title: "Book Title #{i}",
              price: rand(5.0..50.0).round(2)
            }
          end
        }
      }
    end

    it 'compares performance' do
      iterations = 1000

      puts "\n=== Performance Benchmark (#{iterations} iterations) ==="
      
      Benchmark.bm(30) do |x|
        x.report('Optimized (with_schema):') do
          extractor = JsonDataExtractor.with_schema(schema)
          iterations.times { extractor.extract_from(large_data) }
        end

        x.report('Standard (new + extract):') do
          iterations.times do
            JsonDataExtractor.new(large_data).extract(schema)
          end
        end
      end
    end
  end
end
