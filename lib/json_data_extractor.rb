require "src/version"
require "src/node"

class JsonDataExtractor
  def initialize(config)
    @config = config
  end

  def parse(json)
    schemas = config.fetch('schemas', {})
    # binding.pry
    {}.tap do |hash|
      schemas.map do |key, val|
        value = JsonPath.on(json, Node.new(val).path)
        if modifier = val['modifier']
          value.map!{|v| v.respond_to?(modifier) ? v.public_send(modifier) : v}
        end
        hash[key] = value if value
      end
    end
  end

  private

  attr_reader :config
end
