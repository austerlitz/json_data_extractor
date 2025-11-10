# frozen_string_literal: true

require 'spec_helper'
require 'benchmark'

RSpec.describe 'Detailed Performance Benchmarks', :benchmark do
  let(:simple_data) do
    {
      store: {
        book: Array.new(100) do |i|
          {
            category: ['reference', 'fiction', 'mystery'].sample,
            author: "Author #{i}",
            title: "Book Title #{i}",
            price: rand(5.0..50.0).round(2),
            isbn: "ISBN-#{i}"
          }
        end,
        bicycle: { color: 'red', price: 19.95 }
      }
    }
  end

  describe 'Simple paths only (optimal case)' do
    let(:simple_schema) do
      {
        authors: '$.store.book[*].author',
        titles: '$.store.book[*].title',
        prices: '$.store.book[*].price',
        isbns: '$.store.book[*].isbn',
        bike_color: '$.store.bicycle.color'
      }
    end

    it 'shows significant improvement with simple paths' do
      iterations = 5000

      puts "\n=== Simple Paths Benchmark (#{iterations} iterations, 100 books) ==="
      puts "All paths use DirectNavigator (optimized)"
      
      Benchmark.bm(35) do |x|
        optimized_time = x.report('Optimized (with_schema):') do
          extractor = JsonDataExtractor.with_schema(simple_schema)
          iterations.times { extractor.extract_from(simple_data) }
        end

        standard_time = x.report('Standard (new + extract):') do
          iterations.times do
            JsonDataExtractor.new(simple_data).extract(simple_schema)
          end
        end
      end
    end
  end

  describe 'Mixed paths (realistic case)' do
    let(:mixed_schema) do
      {
        authors: { path: '$.store.book[*].author', modifier: :downcase },
        titles: '$.store.book[*].title',
        categories: '$..category', # Forces JsonPath fallback
        bicycle_color: '$.store.bicycle.color'
      }
    end

    it 'shows moderate improvement with mixed paths' do
      iterations = 2000

      puts "\n=== Mixed Paths Benchmark (#{iterations} iterations) ==="
      puts "Simple paths: DirectNavigator | Complex paths: JsonPath fallback"
      
      Benchmark.bm(35) do |x|
        x.report('Optimized (with_schema):') do
          extractor = JsonDataExtractor.with_schema(mixed_schema)
          iterations.times { extractor.extract_from(simple_data) }
        end

        x.report('Standard (new + extract):') do
          iterations.times do
            JsonDataExtractor.new(simple_data).extract(mixed_schema)
          end
        end
      end
    end
  end

  describe 'Schema reuse (batch processing)' do
    let(:schema) do
      {
        authors: '$.store.book[*].author',
        titles: '$.store.book[*].title',
        avg_price: { path: '$.store.book[*].price', modifier: :to_f }
      }
    end

    it 'shows major improvement for batch processing' do
      # Simulate processing 100 separate API responses
      data_batch = Array.new(100) do |batch_idx|
        {
          store: {
            book: Array.new(10) do |i|
              {
                author: "Author #{batch_idx}-#{i}",
                title: "Title #{batch_idx}-#{i}",
                price: rand(10.0..50.0).round(2)
              }
            end
          }
        }
      end

      puts "\n=== Batch Processing Benchmark (100 documents, 10 books each) ==="
      
      Benchmark.bm(35) do |x|
        x.report('Optimized (schema reuse):') do
          extractor = JsonDataExtractor.with_schema(schema)
          data_batch.each { |data| extractor.extract_from(data) }
        end

        x.report('Standard (new each time):') do
          data_batch.each do |data|
            JsonDataExtractor.new(data).extract(schema)
          end
        end
      end
    end
  end

  describe 'Memory allocation comparison' do
    let(:schema) do
      {
        authors: '$.store.book[*].author',
        titles: '$.store.book[*].title'
      }
    end

    it 'shows memory efficiency improvements' do
      require 'objspace'

      puts "\n=== Memory Allocation Comparison ==="
      
      # Warm up
      JsonDataExtractor.with_schema(schema).extract_from(simple_data)
      JsonDataExtractor.new(simple_data).extract(schema)
      
      GC.start
      GC.disable

      before_optimized = ObjectSpace.count_objects
      extractor = JsonDataExtractor.with_schema(schema)
      100.times { extractor.extract_from(simple_data) }
      after_optimized = ObjectSpace.count_objects

      GC.start
      before_standard = ObjectSpace.count_objects
      100.times { JsonDataExtractor.new(simple_data).extract(schema) }
      after_standard = ObjectSpace.count_objects

      GC.enable

      optimized_total = after_optimized[:TOTAL] - before_optimized[:TOTAL]
      standard_total = after_standard[:TOTAL] - before_standard[:TOTAL]

      puts "Optimized objects created:  #{optimized_total.to_s.rjust(10)}"
      puts "Standard objects created:   #{standard_total.to_s.rjust(10)}"
      puts "Reduction:                  #{((1 - optimized_total.to_f / standard_total) * 100).round(1)}%"
      
      expect(optimized_total).to be < standard_total
    end
  end

  describe 'Path compilation impact' do
    it 'measures DirectNavigator vs JsonPath speed' do
      iterations = 10000
      
      data = { store: { book: [{ author: 'Test' }] } }
      path = '$.store.book[*].author'
      
      puts "\n=== Path Navigation Speed (#{iterations} iterations) ==="
      
      Benchmark.bm(35) do |x|
        x.report('DirectNavigator (optimized):') do
          navigator = JsonDataExtractor::DirectNavigator.new(path)
          iterations.times { navigator.on(data) }
        end

        x.report('JsonPath (standard):') do
          json_path = JsonPath.new(path)
          json_string = Oj.dump(data, mode: :compat)
          iterations.times { json_path.on(json_string) }
        end
      end
    end
  end
end
