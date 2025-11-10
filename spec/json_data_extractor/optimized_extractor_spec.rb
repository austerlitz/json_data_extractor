
# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JsonDataExtractor::OptimizedExtractor do
  let(:data) do
    {
      name: 'John Doe',
      age: 30,
      contact: {
        email: 'john@example.com',
        phone: '555-1234'
      },
      hobbies: %w[reading coding gaming]
    }
  end

  describe '#extract_from' do
    it 'extracts simple paths' do
      schema = { name: '$.name', age: '$.age' }
      extractor = described_class.new(schema)
      result = extractor.extract_from(data)

      expect(result).to eq({ name: 'John Doe', age: 30 })
    end

    it 'extracts nested paths' do
      schema = { email: '$.contact.email' }
      extractor = described_class.new(schema)
      result = extractor.extract_from(data)

      expect(result).to eq({ email: 'john@example.com' })
    end

    it 'extracts arrays' do
      schema = { hobbies: { path: '$.hobbies[*]', type: 'array' } }
      extractor = described_class.new(schema)
      result = extractor.extract_from(data)

      expect(result).to eq({ hobbies: %w[reading coding gaming] })
    end

    it 'applies modifiers' do
      schema = { name: { path: '$.name', modifier: :upcase } }
      extractor = described_class.new(schema)
      result = extractor.extract_from(data)

      expect(result).to eq({ name: 'JOHN DOE' })
    end

    it 'applies multiple modifiers' do
      schema = {
        email: {
          path: '$.contact.email',
          modifiers: [:upcase, ->(v) { v.gsub('@', ' AT ') }]
        }
      }
      extractor = described_class.new(schema)
      result = extractor.extract_from(data)

      expect(result[:email]).to eq('JOHN AT EXAMPLE.COM')
    end

    it 'handles default values' do
      schema = {
        missing: { path: '$.nonexistent', default: 'default_value' }
      }
      extractor = described_class.new(schema)
      result = extractor.extract_from(data)

      expect(result).to eq({ missing: 'default_value' })
    end

    it 'handles maps' do
      data_with_codes = { status: 1 }
      schema = {
        status: {
          path: '$.status',
          map: { 1 => 'Active', 2 => 'Inactive', 3 => 'Pending' }
        }
      }
      extractor = described_class.new(schema)
      result = extractor.extract_from(data_with_codes)

      expect(result).to eq({ status: 'Active' })
    end
  end

  describe 'result pre-allocation' do
    it 'creates the correct initial structure' do
      schema = {
        scalar: '$.name',
        array: { path: '$.hobbies[*]', type: 'array' },
        nested: {
          path: '$.contact',
          schema: { email: '$.email' }
        }
      }

      analyzer = JsonDataExtractor::SchemaAnalyzer.new(
        schema,
        JsonDataExtractor::PathCompiler.new
      )

      expect(analyzer.result_template[:scalar]).to be_nil
      expect(analyzer.result_template[:array]).to eq([])
      expect(analyzer.result_template[:nested]).to eq({})
    end
  end
end
