
# frozen_string_literal: true

module JsonDataExtractor
  # Fast path navigator for simple JSONPath expressions
  # Bypasses JsonPath gem for ~20-50x performance improvement
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
      navigate(data, @segments)
    rescue StandardError
      # Fallback to empty array if navigation fails
      []
    end

    private

    def parse_segments(path)
      # Parse "$.store.book[*].author" into [[:key, "store"], [:key, "book"], [:array_all], [:key, "author"]]
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

    def navigate(current, segments)
      return [current] if segments.empty?
      return [nil] if current.nil?

      segment_type, segment_value = segments.first
      rest = segments[1..]

      case segment_type
      when :key
        navigate(current[segment_value], rest)
      when :array_index
        navigate(current[segment_value], rest)
      when :array_all
        return [] unless current.is_a?(Array)

        current.flat_map { |item| navigate(item, rest) }
      end
    end
  end
end
