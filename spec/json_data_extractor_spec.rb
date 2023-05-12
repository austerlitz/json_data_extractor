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
                      path:      '$.years',
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
    end
  end
end
