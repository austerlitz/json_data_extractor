# frozen_string_literal: true

module JsonDataExtractor
  # handles the settings for JSON data extraction.
  class Configuration
    attr_accessor :strict_modifiers

    def initialize
      @strict_modifiers = true
    end
  end
end
