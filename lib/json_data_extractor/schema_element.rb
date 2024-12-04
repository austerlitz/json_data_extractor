module JsonDataExtractor
  class SchemaElement
    attr_reader :path, :default_value, :maps, :modifiers, :array_type, :nested

    def initialize(schema_definition)
      if schema_definition.is_a?(Hash)
        schema_definition.transform_keys!(&:to_sym)

        unless schema_definition.key?(:path) || schema_definition.key?(:default)
          raise ArgumentError, "Either path or default_value must be present in schema definition"
        end

        @path = schema_definition[:path] unless schema_definition[:path].nil?
        @default_value = schema_definition[:default]
        @maps = fetch_maps(schema_definition[:maps] || schema_definition[:map])
        @modifiers = fetch_modifiers(schema_definition[:modifiers] || schema_definition[:modifier])
        @array_type = 'array' == schema_definition[:type]
        @nested = schema_definition[:schema]
      else
        raise ArgumentError, "Schema definition must be a Hash"
      end
    end

    def fetch_default_value
      @default_value.respond_to?(:call) ? @default_value.call : @default_value
    end
    private


    def fetch_maps(map_value)
      Array([map_value]).flatten.compact.map do |map|
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
        when Class
          if mod.respond_to?(:call)
            mod
          else
            raise ArgumentError, "Modifier class must respond to call: #{mod.inspect}"
          end
        when String
          mod.to_sym
        else
          raise ArgumentError, "Invalid modifier: #{mod.inspect}"
        end
      end
    end
  end
end