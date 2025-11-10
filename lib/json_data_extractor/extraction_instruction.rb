# frozen_string_literal: true

module JsonDataExtractor
  # Represents a single field extraction instruction
  class ExtractionInstruction
    attr_reader :key, :element, :compiled_path

    def initialize(key:, element:, compiled_path:)
      @key = key
      @element = element
      @compiled_path = compiled_path
    end

    def extract(data)
      return element.fetch_default_value if compiled_path.nil?

      compiled_path.on(data)
    end
  end
end
