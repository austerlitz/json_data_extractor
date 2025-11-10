require 'spec_helper'

RSpec.describe 'JsonDataExtractor Schema Reuse' do
  let(:locations) do
    [
      {
        'iataCode' => 'AGAC',
        'countryCode' => 'MA',
        'city' => 'Agadir Downtown',
        'name' => 'Agadir Downtown'
      },
      {
        'iataCode' => 'AGP',
        'countryCode' => 'ES',
        'city' => 'Málaga',
        'name' => 'Málaga Airport'
      },
      {
        'iataCode' => 'AGPT',
        'countryCode' => 'ES',
        'city' => 'Málaga',
        'name' => 'María Zambrano Bus Station'
      }
    ]
  end

  let(:schema) do
    {
      code: '$.iataCode',
      iata: '$.iataCode',
      city: '$.city',
      name: '$.name',
      location_type: {
        path: '$.name',
        modifier: ->(name) { name.include?('Airport') ? 'airport' : 'city' }
      }
    }
  end

  describe '.with_schema' do
    it 'creates an extractor with a schema cache' do
      extractor = JsonDataExtractor.with_schema(schema)
      expect(extractor).to be_a(JsonDataExtractor::Extractor)
      expect(extractor.schema_cache).to be_a(JsonDataExtractor::SchemaCache)
    end
  end

  describe '#extract_from' do
    it 'extracts data using the cached schema' do
      extractor = JsonDataExtractor.with_schema(schema)

      result1 = extractor.extract_from(locations[0])
      expect(result1[:code]).to eq('AGAC')
      expect(result1[:location_type]).to eq('city')

      result2 = extractor.extract_from(locations[1])
      expect(result2[:code]).to eq('AGP')
      expect(result2[:location_type]).to eq('airport')
    end

    it 'raises an error if used without a schema cache' do
      extractor = JsonDataExtractor.new({})
      expect { extractor.extract_from({}) }.to raise_error(ArgumentError, /No schema cache available/)
    end

    it 'reuses the cached JsonPath objects' do
      extractor = JsonDataExtractor.with_schema(schema)

      # This test verifies that we're using the cached JsonPath
      # by checking that we don't create new JsonPath objects
      expect(JsonPath).to receive(:new).exactly(0).times

      extractor.extract_from(locations[0])
    end

    it 'processes all locations with the same schema' do
      extractor = JsonDataExtractor.with_schema(schema)

      results = locations.map do |location|
        extractor.extract_from(location)
      end

      expect(results.size).to eq(3)
      expect(results[0][:code]).to eq('AGAC')
      expect(results[1][:code]).to eq('AGP')
      expect(results[2][:code]).to eq('AGPT')

      expect(results[0][:location_type]).to eq('city')
      expect(results[1][:location_type]).to eq('airport')
      expect(results[2][:location_type]).to eq('city')
    end
  end

  context 'performance comparison', :performance do
    it 'is faster than creating new extractors for each data point' do
      # Time the standard approach
      standard_start = Time.now
      locations.each do |location|
        extractor = JsonDataExtractor.new(location)
        extractor.extract(schema)
      end
      standard_time = Time.now - standard_start

      # Time the optimized approach
      optimized_start = Time.now
      extractor = JsonDataExtractor.with_schema(schema)
      locations.each do |location|
        extractor.extract_from(location)
      end
      optimized_time = Time.now - optimized_start

      # The optimized version should be faster
      # Note: This might not be noticeable with small data sets
      # but becomes significant with larger ones
      expect(optimized_time).to be < standard_time
    end
  end
end
