require 'spec_helper'

require "yaml"
require "json"
require "pry"
require "amazing_print"

require 'jsonpath'

RSpec.describe JsonDataExtractor do
  subject { described_class.new(json).extract(config) }

  let!(:json) do
    %q[{ "store": {
          "book": [ 
            { "category": "reference",
              "author": "Nigel Rees",
              "title": "Sayings of the Century",
              "price": 8.95
            },
            { "category": "fiction",
              "author": "Evelyn Waugh",
              "title": "Sword of Honour",
              "price": 12.99
            },
            { "category": "fiction",
              "author": "Herman Melville",
              "title": "Moby Dick",
              "isbn": "0-553-21311-3",
              "price": 8.99
            },
            { "category": "fiction",
              "author": "J. R. R. Tolkien",
              "title": "The Lord of the Rings",
              "isbn": "0-395-19395-8",
              "price": 22.99
            }
          ],
          "bicycle": {
            "color": "red",
            "price": 19.95
          }
        }
      }]
  end
  let!(:yml) do
    <<~YAML
      authors: 
        path: $.store.book[*].author
        modifier: downcase
      categories: $..category
    YAML
  end
  let!(:config) { YAML.safe_load(yml) }

  let!(:expected_result) do
    {
      "authors"    => ["nigel rees", "evelyn waugh", "herman melville", "j. r. r. tolkien"],
      "categories" => ["reference", "fiction", "fiction", "fiction"]
    }
  end

  it 'extracts values according to jsonpath and applies modifiers if present' do
    is_expected.to eq expected_result
  end

  context 'with multiple modifiers' do

    let(:yml) do
      <<~YAML
        authors: 
          path: $.store.book[*].author
          modifiers: [downcase, spaces_to_exclams]
      YAML
    end
    let!(:expected_result) do
      {
        "authors" => ["nigel!rees", "evelyn!waugh", "herman!melville", "j.!r.!r.!tolkien"],
      }
    end
    subject { described_class.new(json, spaces_to_exclams: ->(item) { item.gsub(' ', '!') }).extract(config) }
    it 'applies modifiers in order of appearance' do
      is_expected.to eq expected_result
    end
  end

  context 'returns scalars by default' do
    let(:yml) { 'first_item_price: $.store.book[0].price' }
    let(:expected_result) { { "first_item_price" => 8.95 } }
    it { is_expected.to eq expected_result }

    context 'returns arrays if specifically ordered to' do
      let(:yml) do
        <<~YAML
          first_item_price: 
            path: $.store.book[0].price
            type: array
        YAML
      end
      let(:expected_result) { { "first_item_price" => [8.95] } }
      it { is_expected.to eq expected_result }
    end
  end

  it "has a version number" do
    expect(JsonDataExtractor::VERSION).not_to be nil
  end

  context 'more examples' do
    let(:data) do
      {
        "employees": [
                       {
                         "name":   "John Doe",
                         "email":  "john.doe@example.com",
                         "skills": ["Ruby", "JavaScript"]
                       },
                       {
                         "name":   "Jane Doe",
                         "email":  "jane.doe@example.com",
                         "skills": ["Python", "SQL"]
                       }
                     ]
      }.to_json
    end
    let(:schema) do
      {
        "names":           "$..name",
        "lowercase_names": {
          "path":     "$..name",
          "modifier": :downcase
        },
        "usernames":       {
          "path":      "$..email",
          "modifiers": [:username]
        }
      }
    end
    subject { described_class.new(data) }
    it 'works' do
      subject.add_modifier(:username) { |value| value.split('@').first }
      ap subject.extract(schema)
    end
    it 'is great' do
      ap subject.extract("employee_skills": "$..skills")
    end
  end

  context 'when a ruby Hash is provided in input' do
    let(:json) {
      { name: 'John', email: 'doe@example.org' }
    }
    let(:yml) { 'email: $.email' }
    let(:expected_result) { { 'email' => 'doe@example.org' } }
    it 'converts Hash input objects to json' do
      is_expected.to eq expected_result
    end
  end

  describe 'nested modifiers' do
    let(:json) do
      {
        "employees": [
                       {
                         "name":   "John Doe",
                         "email":  "john.doe@example.com",
                         "skills": ["Ruby", "JavaScript"],
                         "car":    {
                           "make":  "Ford",
                           "model": "Focus",
                         }
                       },
                       {
                         "name":   "Jane Doe",
                         "email":  "jane.doe@example.com",
                         "skills": ["Python", "SQL"],
                         "car":    {
                           "make":  "BMW",
                           "model": "X5",
                         }
                       }
                     ]
      }
    end
    let(:schema) do
      {
        langs: {
          path:   '$.employees[*]',
          type:   'array',
          schema: {
            skills: {
              path:     '$.skills[*]',
              modifier: :append
            }
          }
        }

      }
    end
    subject { described_class.new(json) }
    it 'works with arrays' do

      subject.add_modifier(:append) { |value| value + '...' }
      ap subject.extract(schema)
      json = { "langs": [{ "skills": ["Ruby...", "JavaScript..."] }, { "skills": ["Python...", "SQL..."] }] }
      expect(subject.extract(schema)).to eq(json)
    end
    context 'nested modifiers for non-array type' do

      let(:schema) do
        {
          cars: {
            path:   '$.employees[*]',
            type:   'array',
            schema: {
              name: '$.name',
              car:  {
                path:   '$.car',
                schema: {
                  brand: '$.make'
                }
              }
            }
          }
        }
      end
      it 'works with scalars' do

        ap subject.extract(schema)
        puts subject.extract(schema).to_json
        json = { "cars": [{ "name": "John Doe", "car": { "brand": "Ford" } }, { "name": "Jane Doe", "car": { "brand": "BMW" } }] }
        expect(subject.extract(schema)).to eq(json)
      end
    end
  end

  #########
  describe '#initialize' do
    context 'when given a JSON string' do
      it 'stores the string as data' do
        json_string = '{"name": "Alice", "age": 25}'
        extractor   = JsonDataExtractor.new(json_string)
        expect(extractor.data).to eq(json_string)
      end
    end

    context 'when given a hash' do
      it 'converts the hash to JSON and stores it as data' do
        json_hash   = { name: 'Bob', age: 30 }
        json_string = json_hash.to_json
        extractor   = JsonDataExtractor.new(json_hash)
        expect(extractor.data).to eq(json_string)
      end
    end

    context 'when given modifiers' do
      it 'stores the modifiers as a hash' do
        modifiers = { upcase: ->(s) { s.upcase } }
        extractor = JsonDataExtractor.new('{}', modifiers)
        expect(extractor.modifiers).to eq(modifiers)
      end

    end
  end

  describe '#add_modifier' do
    it 'adds a new modifier to the modifiers hash' do
      extractor = JsonDataExtractor.new('{}')
      modifier  = ->(n) { n + 1 }
      extractor.add_modifier(:increment, &modifier)
      expect(extractor.modifiers).to eq({ increment: modifier })
    end

    it 'converts the modifier name to a symbol' do
      extractor = JsonDataExtractor.new('{}')
      modifier  = ->(n) { n + 1 }
      extractor.add_modifier('increment', &modifier)
      expect(extractor.modifiers).to eq({ increment: modifier })
    end
  end

  describe 'modifiers as lambdas' do
    let(:json_data) do
      <<~JSON
        {
          "name": "John",
          "age": 30,
          "is_active": true,
          "address": {
            "street": "123 Main St",
            "city": "Anytown",
            "state": "CA",
            "zip": "12345"
          },
          "friends": [
            {
              "name": "Jane",
              "age": 28,
              "is_active": false,
              "address": {
                "street": "456 Oak St",
                "city": "Othertown",
                "state": "CA",
                "zip": "67890"
              },
              "hobbies": [
                {
                  "name": "Hiking",
                  "years": 10
                },
                {
                  "name": "Swimming",
                  "years": 5
                }
              ]
            },
            {
              "name": "Bob",
              "age": 35,
              "is_active": true,
              "address": {
                "street": "789 Pine St",
                "city": "Somewhere",
                "state": "CA",
                "zip": "55555"
              },
              "hobbies": [
                {
                  "name": "Reading",
                  "years": 15
                },
                {
                  "name": "Writing",
                  "years": 20
                }
              ]
            }
          ]
        }
      JSON
    end

    describe '#extract' do
      let(:extractor) { described_class.new(json_data) }

      context 'with schema that includes anonymous lambda as modifier' do
        let(:schema) do
          {
            name:    '$.name',
            friends: {
              path:   '$.friends[*]',
              type:   'array',
              schema: {
                name:           '$.name',
                hobbies:        {
                  path:   '$.hobbies[*]',
                  type:   'array',
                  schema: {
                    name:  '$.name',
                    years: {
                      path:     '$.years',
                      modifier: ->(val) { (val * 2).to_s }
                    }
                  }
                },
                address:        {
                  path:   '$.address',
                  schema: {
                    street:    '$.street',
                    city:      '$.city',
                    state:     '$.state',
                    zip:       '$.zip',
                    formatted: {
                      path:      '$.',
                      modifiers: [->(address) { "#{address['street']}, #{address['city']}, #{address['state']} #{address['zip']}" }, :upcase]
                    }
                  }
                },
                formatted_info: {
                  path:      '$.',
                  type:      'array',
                  modifiers: ->(friend) { "#{friend['name']} (#{friend['age']}) - Hobbies: #{friend['hobbies'].map { |h| h['name'] }.join(', ')}" }
                }
              }
            }
          }
        end
        it do
          ap extractor.extract(schema)
        end
      end

      context 'when trying to call an absent modifier' do
        let(:json) {
          { name: 'John', email: 'doe@example.org' }
        }
        let(:yml) do
          <<~YAML
            name: 
              path: $.name
              modifier: invalid_modifier
          YAML
        end
        let(:expected_result) { { 'name' => 'john' } }

        context 'with .strict_modifiers set by default to true' do
          it 'raises an ArgumentError' do
            expect { subject }.to raise_error ArgumentError
          end
        end

        context 'with .strict_modifiers set to false' do
          before do
            JsonDataExtractor.configure do |config|
              config.strict_modifiers = false
            end
          end
          it 'passes value unmodified' do
            expect(subject['name']).to eq 'John'
          end
        end
      end
    end
  end

  describe 'maps' do
    let(:schema) do
      {
        categories: {
          path: "$.store.book[*].category",
          map:  { "fiction" => "Fiction", "reference" => "Reference" }
        }
      }
    end
    subject { described_class.new(json).extract(schema) }

    it 'maps book categories to labels' do
      expect(subject[:categories]).to eq(['Reference', 'Fiction', 'Fiction', 'Fiction'])
    end

    context 'another example' do
      it 'does the job' do
        data = {
          cars: [
                  {make: 'A', fuel: 1},
                  {make: 'B', fuel: 2},
                  {make: 'C', fuel: 3},
                  {make: 'D', fuel: nil},
                ]
        }
        FUEL_TYPES = { 1 => 'Petrol', 2 => 'Diesel', nil => 'Unknown'}
        schema = {
          fuel: {
            path: '$.cars[*].fuel',
            map: FUEL_TYPES
          }
        }
        result = described_class.new(data).extract(schema)
        expect(result).to eq({"fuel":["Petrol","Diesel",nil,"Unknown"]})
      end
    end
  end

  describe 'multiple maps' do
    let(:json) do
      [
        {
          "name":     "Apple",
          "category": "fruit",
          "price":    1.2
        },
        {
          "name":     "Carrot",
          "category": "vegetable",
          "price":    0.5
        },
        {
          "name":     "Chicken",
          "category": "meat",
          "price":    5.99
        }
      ]
    end

    let(:schema) do
      {
        "products": {
          "path": "$..category",
          "maps": [
                    {
                      "fruit"     => "Fresh Fruit",
                      "vegetable" => "Organic Vegetable",
                      "meat"      => "Premium Meat"
                    },
                    {
                      'Fresh Fruit' => 'der Apfel',
                    }
                  ]
        }
      }
    end

    subject { described_class.new(json.to_json).extract(schema) }

    it 'maps product categories and formats prices' do
      ap subject
      expect(subject[:products]).to eq(["der Apfel", nil, nil])
    end
  end



  context 'Default Value Handling' do
    let(:input_data) do
      {
        "existing_key":         "existing_value",
        "another_existing_key": "another_value",
        "nested":               { "key": "nested_value" },
        "array":                [1, 2, 3]
      }

    end
    let(:extractor) { JsonDataExtractor.new(input_data) }

    context 'when key is absent' do
      let(:schema) { { absent_key: { path: nil, default: 'default_value' } } }

      it 'uses the default value' do
        result = extractor.extract(schema)
        expect(result[:absent_key]).to eq('default_value')
      end
    end

    context 'when key is absent without default' do
      let(:schema) { { absent_key: { path: nil } } }

      it 'includes the key in the output with a nil value' do
        result = extractor.extract(schema)
        expect(result).to have_key(:absent_key)
        expect(result[:absent_key]).to be_nil
      end
    end

    context 'when key is absent without default and the path is provided as nil' do
      let(:schema) { { absent_key: nil } }

      it 'includes the key in the output with a nil value' do
        result = extractor.extract(schema)
        expect(result).to have_key(:absent_key)
        expect(result[:absent_key]).to be_nil
      end
    end

    context 'when key is present with default' do
      let(:schema) { { present_key: { path: '$.existing_key', default: 'default_value' } } }

      it 'uses the actual value, not the default' do
        result = extractor.extract(schema)
        expect(result[:present_key]).to eq('existing_value')
      end
    end

    context 'when default is a lambda function' do
      let(:schema) { { dynamic_default: { path: nil, default: -> { 'dynamic_value' } } } }

      it 'uses the dynamic default value' do
        result = extractor.extract(schema)
        expect(result[:dynamic_default]).to eq('dynamic_value')
      end
    end

    context 'when path exists but value is nil' do
      let(:input_data) { { 'some_real_path' => nil }.to_json }
      let(:schema) { { default: { path: '$.some_real_path', default: 'foo' } } }

      it 'uses the default value' do
        result = extractor.extract(schema)
        expect(result).to have_key(:default)
        expect(result[:default]).to eq('foo')
      end
    end

  end
end