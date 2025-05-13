# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JsonDataExtractor::SchemaCache do
  let(:schema) do
    {
      name: '$.name',
      age: {
        path: '$.age',
        modifier: :to_i
      }
    }
  end

  subject { described_class.new(schema) }

  describe '#initialize' do
    it 'stores the schema' do
      expect(subject.schema).to eq(schema)
    end

    it 'creates SchemaElement objects for each key' do
      expect(subject.schema_elements[:name]).to be_a(JsonDataExtractor::SchemaElement)
      expect(subject.schema_elements[:age]).to be_a(JsonDataExtractor::SchemaElement)
    end

    it 'pre-compiles JsonPath objects' do
      expect(subject.path_cache['$.name']).to be_a(JsonPath)
      expect(subject.path_cache['$.age']).to be_a(JsonPath)
    end
  end
end
