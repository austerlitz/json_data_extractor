require 'src/version'
require 'jsonpath'

class JsonDataExtractor
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
      if val.is_a?(Hash)
        val.transform_keys!(&:to_sym)
        path       = val[:path]
        modifiers  = Array(val[:modifiers] || val[:modifier]).map(&:to_sym)
        array_type = 'array' == val[:type]
        nested     = val.dup.delete(:schema)
      else
        path      = val
        modifiers = []
      end

      extracted_data = JsonPath.on(@data, path)

      if extracted_data.empty?
        results[key] = nil
      else
        results[key] = apply_modifiers(extracted_data, modifiers)

        # TODO yeah, this looks ugly. Address it later.
        if !array_type
          results[key] = results[key].first unless 1 < results[key].size
        elsif nested
          results[key] = []
          Array(extracted_data).each do |item|
            results[key] << self.class.new(item).extract(nested)
          end
        end
      end
    end
    results
  end

  private

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
    if modifier.is_a?(Proc)
      modifier.call(value)
    elsif modifiers.key?(modifier)
      modifiers[modifier].call(value)
    elsif value.respond_to?(modifier)
      value.send(modifier)
    else
      value
    end
  end
end
