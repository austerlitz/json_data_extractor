
# frozen_string_literal: true

module JsonDataExtractor
  # Analyzes schema and creates optimized extraction plan
  class SchemaAnalyzer
    attr_reader :extraction_plan, :result_template

    def initialize(schema, modifiers = {})
      @schema = schema
      @modifiers = modifiers
      @path_compiler = PathCompiler.new
      @extraction_plan = []
      @result_template = {}

      analyze_schema
    end

    private

    def analyze_schema
      @schema.each do |key, config|
        element = JsonDataExtractor::SchemaElement.new(
          config.is_a?(Hash) ? config : { path: config }
        )

        # Pre-allocate result slot
        @result_template[key] = determine_initial_value(element)

        # Compile path
        compiled_path = @path_compiler.compile(element.path)

        # Create extraction instruction
        @extraction_plan << ExtractionInstruction.new(
          key: key,
          element: element,
          compiled_path: compiled_path
        )
      end
    end

    def determine_initial_value(element)
      return [] if element.array_type
      return {} if element.nested
      nil
    end
  end
end
