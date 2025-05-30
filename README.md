# JsonDataExtractor

[![Gem Version](https://badge.fury.io/rb/json_data_extractor.svg)](https://badge.fury.io/rb/json_data_extractor)

Transform JSON data structures with the help of a simple schema and JsonPath expressions.
Use the JsonDataExtractor gem to extract and modify data from complex JSON structures using a
straightforward syntax
and a range of built-in or custom modifiers.

_Another try to make something for JSON that is XSLT for XML.
We transform one JSON into another JSON with the help of a third JSON!!!111!!eleventy!!_

Remap one JSON structure into another with some basic rules
and [jsonpath](https://github.com/joshbuddy/jsonpath).

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
and [JSONPath](https://goessner.net/articles/JsonPath/) expressions. The process involves defining a
schema that maps the input JSON structure to the desired output structure.

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

A schema consists of one or more mappings that specify how to extract data from the input JSON and
where to place it in the output JSON.

Each mapping has a path field that specifies the JsonPath expression to use for data extraction, and
an optional modifier field that specifies one or more modifiers to apply to the extracted data.
Modifiers are used to transform the data in some way before placing it in the output JSON.

Here's an example schema that extracts the authors and categories from a JSON structure similar to
the one used in the previous example:

```json
{
  "authors": {
    "path": "$.store.book[*].author",
    "modifier": "downcase"
  },
  "categories": "$..category"
}
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


### Handling Default Values

With JsonDataExtractor, you can specify default values in your schema for keys that might be absent in the input JSON. Use the `path` and `default` keys in the schema for this purpose.

```ruby
schema = {
  absent_value: { path: nil },
  default: { path: '$.some_real_path', default: 'foo' },
  default_with_lambda: { path: '$.table', default: -> { 'DEFAULT' } },
  absent_with_default: { path: nil, default: 'bar' }
}
```

- `absent_value`: Will be `nil` in the output as there's no corresponding key in the input JSON and no default is provided.
- `default`: Will either take the value from `$.some_real_path` in the input JSON or 'foo' if the path does not exist.
- `default_with_lambda`: Will take the value from `$..table` in the input JSON or 'DEFAULT' if the path does not exist.
- `absent_with_default`: Will be 'bar' in the output as there's no corresponding key in the input JSON but a default is provided.

#### Simplified Syntax for Absent Values

For keys that you expect to be absent in the input JSON but still want to include in the output with a `nil` value, you can use a simplified syntax by setting the schema value to `nil`.

```ruby
schema = {
  absent_value: nil
}
```
### Modifiers

Modifiers can be supplied on object creation and/or added later by calling the `#add_modifier` method. Modifiers allow you to perform transformations on the extracted data before it is returned. They are useful for cleaning up data, formatting it, or applying any custom logic.

Modifiers can now be defined in several ways:

1. **By providing a symbol**: This symbol should correspond to the name of a method (e.g., `:to_i`) that will be called on each extracted value.
2. **By providing an anonymous lambda or block**: Use a lambda or block to define the transformation logic inline.
3. **By providing any callable object**: A class or object that implements a `call` method can be used as a modifier. This makes it flexible to use pre-defined classes, lambdas, or procs.

Here’s an example schema showcasing the use of modifiers:

```ruby
schema = {
  name:  '$.name', # Extract as-is
  age:   { path: '$.age', modifier: :to_i }, # Apply the `to_i` method
  email: { 
    path: '$.contact.email', 
    modifiers: [ 
      :downcase, 
      ->(email) { email.gsub(/\s/, '') } # Lambda to remove whitespace
    ]
  }
}
```

- **Name**: The value is simply extracted as-is.
- **Age**: The extracted value is converted to an integer using the `to_i` method.
- **Email**:
  1. The value is transformed to lowercase using `downcase`.
  2. Whitespace is removed using an anonymous lambda.

#### Defining Custom Modifiers

You can define your own custom modifiers using `add_modifier`. A modifier can be defined using a block, a lambda, or any callable object (such as a class that implements `call`):

```ruby
# Using a block
extractor = JsonDataExtractor.new(json_data)
extractor.add_modifier(:remove_newlines) { |value| value.gsub("\n", '') }

# Using a class with a `call` method
class ReverseString
  def call(value)
    value.reverse
  end
end

extractor.add_modifier(:reverse_string, ReverseString.new)

# Lambda example
capitalize = ->(value) { value.capitalize }
extractor.add_modifier(:capitalize, capitalize)

# Apply these modifiers in a schema
schema = {
  name: 'name',
  bio:  { path: 'bio', modifiers: [:remove_newlines, :reverse_string] },
  category: { path: 'category', modifier: :capitalize }
}

# Extract data
results = extractor.extract(schema)
```

#### Modifier Order

Modifiers are called in the order in which they are defined. Keep this in mind when chaining multiple modifiers for complex transformations. For example, if you want to first format a string and then clean it up (or vice versa), define the order accordingly.

You can also configure the behavior of modifiers. By default, JDE raises an `ArgumentError` if a modifier cannot be applied to the extracted value. However, this strict behavior can be configured to ignore such errors. See the **Configuration** section for more details.

### Maps

The JsonDataExtractor gem provides a powerful feature called "maps" that allows you to transform
extracted data using predefined mappings. Maps are useful when you want to convert specific values
from the source data into different values based on predefined rules. The best use case is when you
need to traverse a complex tree to get to a value and them just convert it to your own disctionary.
E.g.:

```ruby
data = {
  cars: [
          { make: 'A', fuel: 1 },
          { make: 'B', fuel: 2 },
          { make: 'C', fuel: 3 },
          { make: 'D', fuel: nil },
        ]
}

FUEL_TYPES = { 1 => 'Petrol', 2 => 'Diesel', nil => 'Unknown' }
schema     = {
  fuel: {
    path: '$.cars[*].fuel',
    map:  FUEL_TYPES
  }
}
result     = JsonDataExtractor.new(data).extract(schema) # => {"fuel":["Petrol","Diesel",nil,"Unknown"]}
```

A map is essentially a dictionary that defines key-value pairs, where the keys represent the source
values and the corresponding values represent the transformed values. When extracting data, you can
apply one or multiple maps to modify the extracted values.

#### Syntax

To define a map, you can use the `map` or `maps` key in the schema. The map value can be a single
hash or an array of hashes, where each hash represents a separate mapping rule. Here's an example:

```ruby
{
  path: "$.data[*].category",
  map:  {
    "fruit"     => "Fresh Fruit",
    "vegetable" => "Organic Vegetable",
    "meat"      => "Premium Meat"
  },
}
```

Multiple maps can also be provided. In this case, each map is applied to the result of previous
transformation:

```ruby
{
  path: "$.data[*].category",
  maps: [
          {
            "fruit"     => "Fresh Fruit",
            "vegetable" => "Organic Vegetable",
            "meat"      => "Premium Meat",
          },
          {
            "Fresh Fruit"       => "Frisches Obst",
            "Organic Vegetable" => "Biologisches Gemüse",
            "Premium Meat"      => "Hochwertiges Fleisch",
          }
        ]
}
```

_(the example is a little bit silly, but you should get the idea of chaining maps)_

You can use keys `:map` and `:maps` interchangeably much like `:modifier`, `:modifiers`.

#### Notes

- Maps can be used together with modifiers but this has less sense as you can always apply complex
  mapping rules in modifiers themselves.
- If used together with modifiers, maps are applied **after** modifiers.
- If a map does not have a key corresponding to a transformed value, it will return nil, be careful
- Maps are applied in the order they are defined in the schema. Be cautious of the order if you have
  overlapping or conflicting mapping rules.

### Nested schemas

JDE supports nested schemas. Just provide your element with a type of `array` and add a `schema` key
for its data.

E.g. this is a valid real-life schema with nested data:

```json
{
  "name": "$.Name",
  "code": "$.Code",
  "services": "$.Services[*].Code",
  "locations": {
    "path": "$.Locations[*]",
    "type": "array",
    "schema": {
      "name": "$.Name",
      "type": "$.Type",
      "code": "$.Code"
    }
  }
}
```

Nested schema can be also applied to objects, not arrays. See specs for more examples.

### Schema Reuse for Performance

When processing multiple data objects with the same schema, JsonDataExtractor provides an optimized approach that avoids redundant schema processing. This is particularly useful for batch processing scenarios where you need to apply the same transformation to multiple data objects.

#### Using `with_schema` and `extract_from`

Instead of creating a new extractor for each data object:

```ruby
data_objects.map do |data|
  extractor = JsonDataExtractor.new(data)
  extractor.extract(schema)
end
```

You can create a single extractor with a pre-processed schema and reuse it:
```ruby
extractor = JsonDataExtractor.with_schema(schema)
data_objects.map do |data|
  extractor.extract_from(data)
end
```

This approach offers significant performance improvements for large datasets by:
1. Pre-processing the schema only once
2. Pre-compiling JsonPath objects
3. Caching schema elements
4. Avoiding redundant schema validation


#### Comparison with Nested Schema Approach

It's worth noting that similar functionality could be achieved using the existing nested schema approach when your data is already in an array format:

```ruby
# Process an array of locations with the nested schema approach
locations_array = [location1, location2, location3]
schema = { 
  all_locations: { 
    path: "[*]", 
    type: "array", 
    schema: { code: ".iataCode", city: ".city", name: ".name" } 
  } 
}
result = JsonDataExtractor.new(locations_array).extract(schema)
# Result: { all_locations: [{code: "...", city: "...", name: "..."}, {...}, {...}] }
```

**When to use which approach:**

1. **Use nested schema when:**
   - Your data is already structured as an array
   - You want to preserve the array structure in your result
   - You need to process the entire array at once

2. **Use schema reuse when:**
   - You receive data objects individually (e.g., from multiple API calls)
   - You need to process each object separately
   - You want to transform each object independently
   - You need direct access to individual results without unwrapping them from an array

The schema reuse approach is specifically optimized for scenarios where you process similar objects multiple times in sequence, rather than all at once in an array.


#### Real-world Example
Here's a practical example of extracting location data from multiple sources:
```ruby
# Location data from an API
locations = [
  {
    "iataCode" => "JFK",
    "countryCode" => "US",
    "city" => "New York",
    "name" => "John F. Kennedy International Airport"
  },
  {
    "iataCode" => "LHR",
    "countryCode" => "GB",
    "city" => "London",
    "name" => "Heathrow Airport"
  }
]

# Define schema once
schema = {
  code: "$.iataCode",
  city: "$.city",
  name: "$.name",
  country: "$.countryCode"
}

# Create an extractor with the schema
jde = JsonDataExtractor.with_schema(schema)

# Process each location efficiently
processed_locations = locations.map do |data|
  jde.extract_from(data)
end

# Result:
# [
#   {code: "JFK", city: "New York", name: "John F. Kennedy International Airport", country: "US"},
#   {code: "LHR", city: "London", name: "Heathrow Airport", country: "GB"}
# ]
```
This pattern is especially beneficial when:
- Processing data in batches that arrive separately
- Working with large datasets where you need to process one item at a time
- Applying the same schema to multiple API responses
- Parsing large collections of similar objects that aren't already in an array structure

## Configuration Options

The JsonDataExtractor gem provides a configuration option to control the behavior when encountering
invalid modifiers.

### Strict Modifiers

By default, the gem operates in strict mode, which means that if an invalid modifier is encountered,
an `ArgumentError` will be raised. This ensures that only valid modifiers are applied to the
extracted data.

To change this behavior and allow the use of invalid modifiers without raising an error, you can
configure the gem to operate in non-strict mode.

```ruby
JsonDataExtractor.configure do |config|
  config.strict_modifiers = false
end
```

When `strict_modifiers` is set to `false`, any invalid modifiers will be ignored, and the original
value will be returned without applying any modification.

It is important to note that enabling non-strict mode should be done with caution, as it can lead to
unexpected behavior if there are typos or incorrect modifiers specified in the schema.

By default, `strict_modifiers` is set to `true`, providing a safe and strict behavior. However, you
can customize this configuration option according to your specific needs.

## TODO

Update this readme for better usage cases. Add info on arrays and modifiers.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run
the tests. You can
also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new
version, update the
version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag
for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub
at https://github.com/austerlitz/json_data_extractor. This project
is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere
to
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of
the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the JsonDataExtractor project’s codebases, issue trackers, chat rooms and
mailing lists is
expected to follow
the [code of conduct](https://github.com/austerlitz/json_data_extractor/blob/master/CODE_OF_CONDUCT.md).
