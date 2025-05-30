# frozen_string_literal: true

module JsonDataExtractor
  # does the main job of the gem
  class Extractor
    attr_reader :data, :modifiers, :schema_cache

    # @param json_data [Hash,String]
    # @param modifiers [Hash]
    def initialize(json_data, modifiers = {})
      @data = json_data.is_a?(Hash) ? Oj.dump(json_data, mode: :compat) : json_data
      @modifiers = modifiers.transform_keys(&:to_sym)
      @results = {}
      @path_cache = {}
    end

    # Creates a new extractor with a pre-processed schema
    # @param schema [Hash] schema of the expected data mapping
    # @param modifiers [Hash] modifiers to apply to the extracted data
    # @return [Extractor] an extractor initialized with the schema
    def self.with_schema(schema, modifiers = {})
      extractor = new({}, modifiers)
      extractor.instance_variable_set(:@schema_cache, SchemaCache.new(schema))
      extractor
    end

    # Extracts data from the provided json_data using the cached schema
    # @param json_data [Hash,String] the data to extract from
    # @return [Hash] the extracted data
    def extract_from(json_data)
      # Ensure we have a schema cache
      raise ArgumentError, 'No schema cache available. Use Extractor.with_schema first.' unless @schema_cache

      # Reset results
      @results = {}

      # Update data
      @data = json_data.is_a?(Hash) ? Oj.dump(json_data, mode: :compat) : json_data

      # Extract data using cached schema
      extract_using_cache

      @results
    end

    # @param modifier_name [String, Symbol]
    # @param callable [#call, nil] Optional callable object
    def add_modifier(modifier_name, callable = nil, &block)
      modifier_name = modifier_name.to_sym unless modifier_name.is_a?(Symbol)
      modifiers[modifier_name] = callable || block

      return if modifiers[modifier_name].respond_to?(:call)

      raise ArgumentError, 'Modifier must be a callable object or a block'
    end

    # @param schema [Hash] schema of the expected data mapping
    def extract(schema)
      schema.each do |key, val|
        element = JsonDataExtractor::SchemaElement.new(val.is_a?(Hash) ? val : { path: val })

        path = element.path
        json_path = path ? (@path_cache[path] ||= JsonPath.new(path)) : nil

        extracted_data = json_path&.on(@data)

        if extracted_data.nil? || extracted_data.empty?
          # we either got nothing or the `path` was initially nil
          @results[key] = element.fetch_default_value
          next
        end

        # check for nils and apply defaults if applicable
        extracted_data.map! { |item| item.nil? ? element.fetch_default_value : item }

        # apply modifiers if present
        extracted_data = apply_modifiers(extracted_data, element.modifiers) if element.modifiers.any?

        # apply maps if present
        @results[key] = element.maps.any? ? apply_maps(extracted_data, element.maps) : extracted_data

        @results[key] = resolve_result_structure(@results[key], element)
      end

      @results
    end

    private

    # Extracts data using the cached schema
    def extract_using_cache
      schema_cache.schema.each do |key, _|
        element = schema_cache.schema_elements[key]
        path = element.path

        # Use cached JsonPath object
        json_path = path ? schema_cache.path_cache[path] : nil

        extracted_data = json_path&.on(@data)

        if extracted_data.nil? || extracted_data.empty?
          # we either got nothing or the `path` was initially nil
          @results[key] = element.fetch_default_value
          next
        end

        # check for nils and apply defaults if applicable
        extracted_data.map! { |item| item.nil? ? element.fetch_default_value : item }

        # apply modifiers if present
        extracted_data = apply_modifiers(extracted_data, element.modifiers) if element.modifiers.any?

        # apply maps if present
        @results[key] = element.maps.any? ? apply_maps(extracted_data, element.maps) : extracted_data

        @results[key] = resolve_result_structure(@results[key], element)
      end
    end

    def resolve_result_structure(result, element)
      if element.nested
        # Process nested data
        result = extract_nested_data(result, element.nested)
        return element.array_type ? result : result.first
      end

      # Handle single-item extraction if not explicitly an array type or having multiple items
      return result.first if result.size == 1 && !element.array_type

      # Default case: simply return the result, assuming it's correctly formed
      result
    end

    def extract_nested_data(data, schema)
      Array(data).map do |item|
        self.class.new(item, modifiers).extract(schema)
      end
    end

    def apply_maps(data, maps)
      data.map do |value|
        maps.reduce(value) { |mapped_value, map| map[mapped_value] }
      end
    end

    def apply_modifiers(data, modifiers)
      data.map do |value|
        modifiers.reduce(value) do |modified_value, modifier|
          apply_single_modifier(modifier, modified_value)
        end
      end
    end

    def apply_single_modifier(modifier, value)
      return modifier.call(value) if modifier.respond_to?(:call)
      return modifiers[modifier].call(value) if modifiers.key?(modifier)
      return value.public_send(modifier) if value.respond_to?(modifier)

      if JsonDataExtractor.configuration.strict_modifiers
        raise ArgumentError, "Modifier: <:#{modifier}> cannot be applied to value <#{value.inspect}>"
      end

      value
    end
  end
end
