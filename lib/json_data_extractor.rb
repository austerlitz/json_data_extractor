require "src/version"

class JsonDataExtractor
  attr_reader :json_data, :modifiers

  def initialize(json_data, modifiers = {})
    @json_data = json_data
    @modifiers = modifiers
  end

  def add_modifier(modifier_name, &block)
    modifiers[modifier_name] = block
  end

  def extract(schema)
    results = {}
    schema.each do |key, val|
      path = val.is_a?(Hash) && val['path'] ? val['path'] : val
      modifiers = val.is_a?(Hash) ? Array(val['modifiers'] || val['modifier']) : []

      json_path = JsonPath.new(path)
      extracted_data = json_path.on(@json_data).flatten.compact

      if extracted_data.empty?
        results[key] = nil
      else
        results[key] = apply_modifiers(extracted_data, modifiers)
        unless val.is_a?(Hash) && val['type'] && 'array' == val['type']
          results[key] = results[key].first unless 1 < results[key].size
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
        if @modifiers.key?(modifier)
          modified_value = @modifiers[modifier].call(modified_value)
        else
          modified_value = apply_single_modifier(modifier, modified_value)
        end
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
