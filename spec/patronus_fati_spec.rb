require 'spec_helper'

RSpec.describe PatronusFati do
  context 'VERSION' do
    it 'should have a version' do
      expect { PatronusFati::VERSION }.to_not raise_error
    end

    it 'should be properly formatted' do
      expect(PatronusFati::VERSION).to match(/\d+\.\d+\.\d+([a-z])?/)
    end
  end
end
