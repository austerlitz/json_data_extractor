
# frozen_string_literal: true

module JsonDataExtractor
  # Fast path navigator for simple JSONPath expressions
  # Optimized to minimize recursive calls
  class DirectNavigator
    SIMPLE_PATH_PATTERN = /^\$(\.[a-zA-Z_][\w]*|\[\d+\]|\[\*\])+$/

    def self.simple_path?(path)
      path&.match?(SIMPLE_PATH_PATTERN)
    end

    def initialize(path)
      @path = path
      @segments = parse_segments(path)
    end

    def on(data)
      # Use iterative approach instead of recursion to reduce method calls
      navigate(data)
    rescue StandardError => e
      # Fallback to empty array if navigation fails
      []
    end

    private

    def parse_segments(path)
      # Parse "$.store.book[*].author" into segment instructions
      path.sub(/^\$/, '').scan(/\.\w+|\[\d+\]|\[\*\]/).map do |segment|
        case segment
        when /^\[(\d+)\]$/
          [:array_index, ::Regexp.last_match(1).to_i]
        when /^\[\*\]$/
          [:array_all]
        when /^\.(\w+)$/
          [:key, ::Regexp.last_match(1)]
        end
      end
    end

    # Iterative navigation - much faster than recursion
    def navigate(data)
      current_values = [data]
      
      @segments.each do |segment_type, segment_value|
        next_values = []
        
        current_values.each do |current|
          # Skip only if current is nil AND we haven't found anything yet
          # This allows nil values that were explicitly extracted to pass through
          next if current.nil?
          
          case segment_type
          when :key
            # Try both string and symbol keys
            if current.is_a?(Hash)
              val = current[segment_value] || current[segment_value.to_sym]
              next_values << val
            end
          when :array_index
            if current.is_a?(Array)
              next_values << current[segment_value]
            end
          when :array_all
            if current.is_a?(Array)
              next_values.concat(current)
            end
          end
        end
        
        current_values = next_values
      end
      
      # Don't use compact - it removes nil values which might be intentional!
      # Only remove nils that result from failed navigation (not explicit nil values)
      current_values
    end
  end
end
