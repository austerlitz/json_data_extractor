# frozen_string_literal: true

module JsonDataExtractor
  # parses the input schema element
  class SchemaElement
    attr_reader :path, :default_value, :maps, :modifiers, :array_type, :nested

    def initialize(schema_definition)
      validate_schema_definition(schema_definition)

      @path = schema_definition[:path] if schema_definition.key?(:path)
      @default_value = schema_definition[:default]
      @maps = fetch_maps(schema_definition[:maps] || schema_definition[:map])
      @modifiers = fetch_modifiers(schema_definition[:modifiers] || schema_definition[:modifier])
      @array_type = schema_definition[:type] == 'array'
      @nested = schema_definition[:schema]
    end

    def fetch_default_value
      @default_value.respond_to?(:call) ? @default_value.call : @default_value
    end

    private

    def validate_schema_definition(schema_definition)
      raise ArgumentError, 'Schema definition must be a Hash' unless schema_definition.is_a?(Hash)
      raise ArgumentError, 'Schema definition must not be empty' if schema_definition.empty?

      schema_definition.transform_keys!(&:to_sym)

      return if schema_definition.key?(:path) || schema_definition.key?(:default)

      raise ArgumentError, 'Either path or default_value must be present in schema definition'
    end

    def fetch_maps(map_value)
      Array([map_value]).flatten.compact.map do |map|
        raise ArgumentError, "Invalid map: #{map.inspect}" unless map.is_a?(Hash)

        map
      end
    end

    def fetch_modifiers(modifier_value)
      Array(modifier_value).map do |mod|
        case mod
        when Symbol, Proc; then mod
        when Class; then validate_modifier_class(mod)
        when String; then mod.to_sym
        else
          raise ArgumentError, "Invalid modifier: #{mod.inspect}"
        end
      end
    end

    def validate_modifier_class(mod)
      raise ArgumentError, "Modifier class must respond to call: #{mod.inspect}" unless mod.respond_to?(:call)

      mod
    end
  end
end
