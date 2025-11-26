# frozen_string_literal: true

require 'oj'

module JsonDataExtractor
  # High-performance single-pass extractor
  class OptimizedExtractor
    attr_reader :modifiers

    def initialize(schema, modifiers: {})
      @modifiers = modifiers.transform_keys(&:to_sym)
      @schema_analyzer = SchemaAnalyzer.new(schema, @modifiers)
    end

    def extract_from(json_data)
      # Pre-allocate result from template
      result = deep_dup(@schema_analyzer.result_template)

      # Parse JSON once
      data = parse_data(json_data)

      # Execute extraction plan
      @schema_analyzer.extraction_plan.each do |instruction|
        extract_and_fill(data, instruction, result)
      end

      result
    end

    def add_modifier(modifier_name, callable = nil, &block)
      modifier_name = modifier_name.to_sym unless modifier_name.is_a?(Symbol)
      @modifiers[modifier_name] = callable || block

      return if @modifiers[modifier_name].respond_to?(:call)

      raise ArgumentError, 'Modifier must be a callable object or a block'
    end

    private

    def extract_and_fill(data, instruction, result)
      element = instruction.element

      # Navigate and extract using compiled_path (not navigator)
      extracted_data = if instruction.compiled_path
                         instruction.compiled_path.on(data)
                       else
                         []
                       end

      # Handle empty/nil results
      if extracted_data.nil? || extracted_data.empty?
        result[instruction.key] = element.fetch_default_value
        return
      end

      # Apply defaults for nil values
      extracted_data.map! { |item| item.nil? ? element.fetch_default_value : item }

      # Apply transformations in place
      apply_transformations!(extracted_data, element)

      # Store result
      result[instruction.key] = resolve_result_structure(extracted_data, element)
    end

    def apply_transformations!(values, element)
      # Apply modifiers
      if element.modifiers.any?
        values.map! do |value|
          element.modifiers.reduce(value) do |v, modifier|
            apply_single_modifier(modifier, v)
          end
        end
      end

      # Apply maps
      if element.maps.any?
        values.map! do |value|
          element.maps.reduce(value) { |v, map| map[v] }
        end
      end
    end

    def resolve_result_structure(result, element)
      if element.nested
        # Process nested data
        result = extract_nested_data(result, element.nested)
        return element.array_type ? result : result.first
      end

      # Handle single-item extraction if not explicitly an array type
      return result.first if result.size == 1 && !element.array_type

      result
    end

    def extract_nested_data(data, schema)
      Array(data).map do |item|
        self.class.new(schema, modifiers: @modifiers).extract_from(item)
      end
    end

    def apply_single_modifier(modifier, value)
      return modifier.call(value) if modifier.respond_to?(:call)
      return @modifiers[modifier].call(value) if @modifiers.key?(modifier)
      return value.public_send(modifier) if value.respond_to?(modifier)

      if JsonDataExtractor.configuration.strict_modifiers
        raise ArgumentError, "Modifier: <:#{modifier}> cannot be applied to value <#{value.inspect}>"
      end

      value
    end

    def parse_data(json_data)
      return json_data if json_data.is_a?(Hash) || json_data.is_a?(Array)
      Oj.load(json_data)
    end

    def deep_dup(obj)
      case obj
      when Hash
        obj.each_with_object({}) { |(k, v), h| h[k] = deep_dup(v) }
      when Array
        obj.map { |v| deep_dup(v) }
      else
        obj.duplicable? ? obj.dup : obj
      end
    end
  end
end

    # Ruby basic types helper
class Object
  def duplicable?
    true
  end
end

class NilClass
  def duplicable?
    false
  end
end

class FalseClass
  def duplicable?
    false
  end
end

class TrueClass
  def duplicable?
    false
  end
end

class Symbol
  def duplicable?
    false
  end
end

class Numeric
  def duplicable?
    false
  end
end
