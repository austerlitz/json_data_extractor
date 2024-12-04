class Extractor
  attr_reader :data, :modifiers

  def initialize(json_data, modifiers = {})
    @data = json_data.is_a?(Hash) ? json_data.to_json : json_data # hopefully it's a string; maybe we'll add some validation here
    @modifiers = modifiers.transform_keys(&:to_sym) # todo address this later
  end

  # @param modifier_name [String, Symbol]
  def add_modifier(modifier_name, &block)
    modifier_name = modifier_name.to_sym unless modifier_name.is_a?(Symbol)
    modifiers[modifier_name] = block
  end

  # @param schema [Hash] schema of the expected data mapping
  def extract(schema)
    results = {}
    schema.each do |key, val|
      element = JsonDataExtractor::SchemaElement.new(val.is_a?(Hash) ? val : { path: val })

      extracted_data = JsonPath.on(@data, element.path) if element.path

      if extracted_data.nil? || extracted_data.empty?
        # we either got nothing or the `path` was initially nil
        results[key] = element.fetch_default_value
        next
      end

      # check for nils and apply defaults if applicable
      extracted_data.map! { |item| item.nil? ? element.fetch_default_value : item }

      # apply modifiers if present
      extracted_data = apply_modifiers(extracted_data, element.modifiers) if element.modifiers.any?

      # apply maps if present
      results[key] = element.maps.any? ? apply_maps(extracted_data, element.maps) : extracted_data

      results[key] = resolve_result_structure(results[key], element)
    end
    results
  end

  private

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
      value.public_send(modifier)
    elsif JsonDataExtractor.configuration.strict_modifiers
      raise ArgumentError, "Modifier: <:#{modifier}> cannot be applied to value <#{value.inspect}>"
    else
      value
    end
  end

end