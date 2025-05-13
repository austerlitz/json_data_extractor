# frozen_string_literal: true

module JsonDataExtractor
  # Caches schema elements to avoid re-processing the schema for each data extraction
  class SchemaCache
    attr_reader :schema, :schema_elements, :path_cache

    def initialize(schema)
      @schema = schema
      @schema_elements = {}
      @path_cache = {}
      
      # Pre-process the schema to create SchemaElement objects
      process_schema
    end

    private

    def process_schema
      schema.each do |key, val|
        # Store the SchemaElement for each key in the schema
        @schema_elements[key] = JsonDataExtractor::SchemaElement.new(val.is_a?(Hash) ? val : { path: val })
        
        # Pre-compile JsonPath objects for each path
        path = @schema_elements[key].path
        @path_cache[path] = JsonPath.new(path) if path
      end
    end
  end
end