module JsonDataExtractor
  class Configuration
    attr_accessor :strict_modifiers

    def initialize
      @strict_modifiers = true
    end
  end
end