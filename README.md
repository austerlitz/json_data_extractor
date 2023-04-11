# JsonDataExtractor

NOTE: This is still a very early beta.

Transform JSON data structures with the help of a simple schema and JsonPath expressions.
Use the JsonDataExtractor gem to extract and modify data from complex JSON structures using a straightforward syntax
and a range of built-in or custom modifiers.

_Another try to make something for JSON that is XSLT for XML.
We transform one JSON into another JSON with the help of a third JSON!!!111!!eleventy!!_

Remap one JSON structure into another with some basic rules and [jsonpath](https://github.com/joshbuddy/jsonpath).

Heavily inspired by [xml_data_extractor](https://github.com/monde-sistemas/xml_data_extractor).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'json_data_extractor'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install json_data_extractor

## Usage

JsonDataExtractor allows you to remap one JSON structure into another with some basic rules
and [JSONPath](https://goessner.net/articles/JsonPath/) expressions. The process involves defining a schema that maps
the input JSON structure to the desired output structure.

We'll base our examples on the following source:

```json
{
  "store": {
    "book": [
      {
        "category": "reference",
        "author": "Nigel Rees",
        "title": "Sayings of the Century",
        "price": 8.95
      },
      {
        "category": "fiction",
        "author": "Evelyn Waugh",
        "title": "Sword of Honour",
        "price": 12.99
      },
      {
        "category": "fiction",
        "author": "Herman Melville",
        "title": "Moby Dick",
        "isbn": "0-553-21311-3",
        "price": 8.99
      },
      {
        "category": "fiction",
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
}
```

### Defining a Schema

A schema consists of one or more mappings that specify how to extract data from the input JSON and where to place it in
the output JSON.

Each mapping has a path field that specifies the JsonPath expression to use for data extraction, and an optional
modifier field that specifies one or more modifiers to apply to the extracted data. Modifiers are used to transform the
data in some way before placing it in the output JSON.

Here's an example schema that extracts the authors and categories from a JSON structure similar to the one used in the
previous example (here it's in YAML just for readability):

```yaml
schemas:
  authors:
    path: $.store.book[*].author
    modifier: downcase
  categories: $..category
```

The resulting json will be:

```json
{
  "authors": [
    "nigel rees",
    "evelyn waugh",
    "herman melville",
    "j. r. r. tolkien"
  ],
  "categories": [
    "reference",
    "fiction",
    "fiction",
    "fiction"
  ]
}

```

Modifiers can be supplied on object creation and/or added later by calling `#add_modifier` method. Please see specs for
examples.

### Nested schemas

JDE supports nested schemas. Just provide your element with a type of `array` and add a `schema` key for its data.

E.g. this is a valid real-life schema with nested data:

```json
{
  name:      '$.Name',
  code:      '$.Code',
  services:  '$.Services[*].Code',
  locations: {
    path:   '$.Locations[*]',
    type:   'array',
    schema: {
      name: '$.Name',
      type: '$.Type',
      code: '$.Code'
    }
  }
}
```

## TODO

Update this readme for better usage cases. Add info on arrays and modifiers.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can
also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the
version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/austerlitz/json_data_extractor. This project
is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the JsonDataExtractor project’s codebases, issue trackers, chat rooms and mailing lists is
expected to follow
the [code of conduct](https://github.com/austerlitz/json_data_extractor/blob/master/CODE_OF_CONDUCT.md).
