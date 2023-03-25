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
      "authors":    ["nigel rees", "evelyn waugh", "herman melville", "j. r. r. tolkien"],
      "categories": ["reference", "fiction", "fiction", "fiction"]
    }
  end

  it 'does the thing' do
    puts JSON.pretty_generate(subject)
    expect(JSON.pretty_generate(subject)).to eq JSON.pretty_generate(expected_result)
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
        "authors": ["nigel!rees", "evelyn!waugh", "herman!melville", "j.!r.!r.!tolkien"],
      }
    end
    subject { described_class.new(json, spaces_to_exclams: ->(item) { item.gsub(' ', '!') }).extract(config) }
    it 'does the thing' do
      puts JSON.pretty_generate(subject)
      expect(JSON.pretty_generate(subject)).to eq JSON.pretty_generate(expected_result)
    end
  end

  context 'returns scalars by default' do
    let(:yml) { 'first_item_price: $.store.book[0].price' }
    let(:expected_result) { { "first_item_price": 8.95 } }
    it 'does the thing' do
      puts JSON.pretty_generate(subject)
      expect(JSON.pretty_generate(subject)).to eq JSON.pretty_generate(expected_result)
    end
  end

  it "has a version number" do
    expect(JsonDataExtractor::VERSION).not_to be nil
  end

end
