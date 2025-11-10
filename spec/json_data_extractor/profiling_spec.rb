
# frozen_string_literal: true

require 'spec_helper'

begin
  require 'ruby-prof'
  RUBY_PROF_AVAILABLE = true
rescue LoadError
  RUBY_PROF_AVAILABLE = false
end

RSpec.describe 'Performance Profiling', :profiling do
  # Run with: rspec spec/json_data_extractor/profiling_spec.rb --tag profiling
  # Requires: gem install ruby-prof

  let(:data) do
    {
      store: {
        book: Array.new(100) do |i|
          {
            author: "Author #{i}",
            title: "Title #{i}",
            price: rand(10.0..50.0).round(2)
          }
        end
      }
    }
  end

  let(:schema) do
    {
      authors: '$.store.book[*].author',
      titles: '$.store.book[*].title',
      prices: '$.store.book[*].price'
    }
  end

  it 'profiles optimized extraction' do
    skip 'ruby-prof not installed' unless RUBY_PROF_AVAILABLE

    puts "\n=== Profiling Optimized Extraction (1000 iterations) ==="
    
    profile = RubyProf::Profile.new
    profile.start

    extractor = JsonDataExtractor.with_schema(schema)
    1000.times { extractor.extract_from(data) }

    result = profile.stop

    # Print flat profile
    puts "\n--- Top Methods by Self Time ---"
    printer = RubyProf::FlatPrinter.new(result)
    printer.print(STDOUT, min_percent: 1)
  end

  it 'compares optimized vs standard profiling' do
    skip 'ruby-prof not installed' unless RUBY_PROF_AVAILABLE

    puts "\n=== Comparing Optimized vs Standard (500 iterations each) ==="

    # Profile optimized
    optimized_profile = RubyProf::Profile.new
    optimized_profile.start
    extractor = JsonDataExtractor.with_schema(schema)
    500.times { extractor.extract_from(data) }
    optimized_result = optimized_profile.stop

    # Profile standard
    standard_profile = RubyProf::Profile.new
    standard_profile.start
    500.times { JsonDataExtractor.new(data).extract(schema) }
    standard_result = standard_profile.stop

    puts "\n--- OPTIMIZED (with_schema) ---"
    RubyProf::FlatPrinter.new(optimized_result).print(STDOUT, min_percent: 2)

    puts "\n--- STANDARD (new + extract) ---"
    RubyProf::FlatPrinter.new(standard_result).print(STDOUT, min_percent: 2)
  end
end
