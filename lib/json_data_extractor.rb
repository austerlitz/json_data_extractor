require 'json_data_extractor/version'
require 'json_data_extractor/configuration'
require 'jsonpath'

module JsonDataExtractor
  class Extractor
    attr_reader :data, :modifiers

    def initialize(json_data, modifiers = {})
      @data      = json_data.is_a?(Hash) ? json_data.to_json : json_data # hopefully it's a string; maybe we'll add some validation here
      @modifiers = modifiers.transform_keys(&:to_sym) # todo address this later
    end

    # @param modifier_name [String, Symbol]
    def add_modifier(modifier_name, &block)
      modifier_name            = modifier_name.to_sym unless modifier_name.is_a?(Symbol)
      modifiers[modifier_name] = block
    end

    # @param schema [Hash] schema of the expected data mapping
    def extract(schema)
      results = {}
      schema.each do |key, val|
        default_value  = nil
        if val.is_a?(Hash)
          val.transform_keys!(&:to_sym)
          path          = val[:path]
          default_value = val[:default]
          maps          = Array([val[:maps] || val[:map]]).flatten.compact.map do |map|
            if map.is_a?(Hash)
              map
            else
              raise ArgumentError, "Invalid map: #{map.inspect}"
            end
          end
          modifiers     = Array(val[:modifiers] || val[:modifier]).map do |mod|
            case mod
            when Symbol, Proc
              mod
            when String
              mod.to_sym
            else
              raise ArgumentError, "Invalid modifier: #{mod.inspect}"
            end
          end
          array_type    = 'array' == val[:type]
          nested        = val.dup.delete(:schema)
        else
          path      = val
          modifiers = []
          maps      = []
        end

        extracted_data = JsonPath.on(@data, path) if path

        if extracted_data.nil? || extracted_data.empty?
          results[key] = default_value.is_a?(Proc) ? default_value.call : (default_value || nil)
        else
          extracted_data.map! { |val| val.nil? ? default_value : val }
          transformed_data = apply_modifiers(extracted_data, modifiers)
          results[key]     = apply_maps(transformed_data, maps)

          if array_type && nested
            results[key] = extract_nested_data(results[key], nested)
          elsif !array_type && nested
            results[key] = extract_nested_data(results[key], nested).first
          elsif !array_type && 1 < results[key].size
            # TODO: handle case where results[key] has more than one item
            # do nothing for now
          elsif array_type && !nested
            # do nothing, it is already an array
          else
            results[key] = results[key].first
          end
        end
      end
      results
    end

    private

    def extract_nested_data(data, schema)
      Array(data).map do |item|
        self.class.new(item, modifiers).extract(schema)
      end
    end

    def apply_maps(data, maps)
      data.map do |value|
        mapped_value = value
        maps.each { |map| mapped_value = map[mapped_value] }
        mapped_value
      end
    end

    def apply_modifiers(data, modifiers)
      data.map do |value|
        modified_value = value
        modifiers.each do |modifier|
          modified_value = apply_single_modifier(modifier, modified_value)
        end
        modified_value
      end
    end

    def apply_single_modifier(modifier, value)
      if modifier.respond_to?(:call) # Matches Proc, Lambda, Method, and callable objects
        modifier.call(value)
      elsif modifiers.key?(modifier)
        modifiers[modifier].call(value)
      elsif value.respond_to?(modifier)
        value.send(modifier)
      elsif JsonDataExtractor.configuration.strict_modifiers
        raise ArgumentError, "Modifier: <:#{modifier}> cannot be applied to value <#{value.inspect}>"
      else
        value
      end
    end

  end

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
