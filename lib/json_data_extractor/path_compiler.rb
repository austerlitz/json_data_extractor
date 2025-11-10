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
        JsonPathWrapper.new(path)
      end
    end

    # Wrapper for JsonPath that caches serialization
    class JsonPathWrapper
      def initialize(path)
        @json_path = JsonPath.new(path)
        @cached_json = nil
        @cached_data_id = nil
      end

      def on(data)
        # Cache the JSON serialization if we're processing the same data object
        data_id = data.object_id
        
        if data.is_a?(String)
          @json_path.on(data)
        else
          # Only serialize once per data object
          if @cached_data_id != data_id
            @cached_json = Oj.dump(data, mode: :compat)
            @cached_data_id = data_id
          end
          @json_path.on(@cached_json)
        end
      end
    end
  end
end
