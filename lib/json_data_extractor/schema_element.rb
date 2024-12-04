module JsonDataExtractor
  class SchemaElement
    attr_reader :path, :default_value, :maps, :modifiers, :array_type, :nested

    def initialize(schema_definition)
      schema_definition.transform_keys!(&:to_sym)
      @path = schema_definition[:path]
      @default_value = schema_definition[:default]
      @maps = fetch_maps([schema_definition[:maps] || schema_definition[:map]])
      @modifiers = fetch_modifiers(schema_definition[:modifiers] || schema_definition[:modifier])
      @array_type = 'array' == schema_definition[:type]
      @nested = schema_definition[:schema]
    end

    private

    def fetch_maps(map_value)
      Array(map_value).flatten.compact.map do |map|
        if map.is_a?(Hash)
          map
        else
          raise ArgumentError, "Invalid map: #{map.inspect}"
        end
      end
    end

    def fetch_modifiers(modifier_value)
      Array(modifier_value).map do |mod|
        case mod
        when Symbol, Proc
          mod
        when String
          mod.to_sym
        else
          raise ArgumentError, "Invalid modifier: #{mod.inspect}"
        end
      end
    end
  end
end