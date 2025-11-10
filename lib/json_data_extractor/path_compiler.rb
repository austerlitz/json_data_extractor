# frozen_string_literal: true

module JsonDataExtractor
  # Compiles JSONPath expressions into optimized navigators
  class PathCompiler
    def compile(path)
      return nil unless path

      if DirectNavigator.simple_path?(path)
        DirectNavigator.new(path)
      else
        # Fallback to JsonPath for complex expressions
        JsonPath.new(path)
      end
    end
  end
end
