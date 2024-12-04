require 'jsonpath'
require_relative 'json_data_extractor/version'
require_relative 'json_data_extractor/configuration'
require_relative 'json_data_extractor/extractor'
require_relative 'json_data_extractor/schema_element'

module JsonDataExtractor
  class << self
    # Backward compatibility
    def new(*args)
      Extractor.new(*args)
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
