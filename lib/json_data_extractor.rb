# frozen_string_literal: true

require 'jsonpath'
require 'multi_json'
require 'oj'
require_relative 'json_data_extractor/version'
require_relative 'json_data_extractor/configuration'
require_relative 'json_data_extractor/extractor'
require_relative 'json_data_extractor/schema_element'

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

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
