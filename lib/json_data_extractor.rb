# frozen_string_literal: true

require 'jsonpath'
require 'multi_json'
require 'oj'
require_relative 'json_data_extractor/version'
require_relative 'json_data_extractor/configuration'
require_relative 'json_data_extractor/schema_element'
require_relative 'json_data_extractor/schema_cache'
require_relative 'json_data_extractor/extractor'

# Set MultiJson to use Oj for performance
MultiJson.use(:oj)
Oj.default_options = { mode: :compat }

# Transform JSON data structures with the help of a simple schema and JsonPath expressions.
# Use the JsonDataExtractor gem to extract and modify data from complex JSON structures using a straightforward syntax
# and a range of built-in or custom modifiers.
module JsonDataExtractor
  class << self
    # Backward compatibility
    def new(*args)
      Extractor.new(*args)
    end

    # Creates a new extractor with a pre-processed schema
    # @param schema [Hash] schema of the expected data mapping
    # @param modifiers [Hash] modifiers to apply to the extracted data
    # @return [Extractor] an extractor initialized with the schema
    def with_schema(schema, modifiers = {})
      Extractor.with_schema(schema, modifiers)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
