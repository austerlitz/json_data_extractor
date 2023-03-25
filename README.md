# JsonDataExtractor

Another try to make something for JSON that is XSLT for XML. 
We transform one JSON into another JSON with the help of a third JSON!!!111!!eleventy!!

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

Assuming you are familiar with [JSONPath](https://goessner.net/articles/JsonPath/), you can write simple mappers that will remap incoming data into the structure you need.

With the following source:

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

and the following schema:

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
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/austerlitz/json_data_extractor. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the JsonDataExtractor project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/austerlitz/json_data_extractor/blob/master/CODE_OF_CONDUCT.md).