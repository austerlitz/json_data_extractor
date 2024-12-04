# frozen_string_literal: true


RSpec.describe JsonDataExtractor::Configuration do

  describe '#strict_modifiers' do
    it 'has a default value of true' do
      expect(JsonDataExtractor::Configuration.new.strict_modifiers).to be(true)
    end

    it 'can be set to false' do
      config = JsonDataExtractor::Configuration.new
      config.strict_modifiers = false
      expect(config.strict_modifiers).to be(false)
    end
  end
end
