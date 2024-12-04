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

      if element.array_type && element.nested
        results[key] = extract_nested_data(results[key], element.nested)
      elsif !element.array_type && element.nested
        results[key] = extract_nested_data(results[key], element.nested).first
      elsif !element.array_type && 1 < results[key].size
        # TODO: handle case where results[key] has more than one item
        # do nothing for now
      elsif element.array_type && !element.nested
        # do nothing, it is already an array
      else
        results[key] = results[key].first
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
      value.public_send(modifier)
    elsif JsonDataExtractor.configuration.strict_modifiers
      raise ArgumentError, "Modifier: <:#{modifier}> cannot be applied to value <#{value.inspect}>"
    else
      value
    end
  end

end