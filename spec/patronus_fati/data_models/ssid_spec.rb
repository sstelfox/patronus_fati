require 'spec_helper'

RSpec.describe(PatronusFati::DataModels::Ssid) do
  subject { described_class.new('88:88:88:99:99:99') }

  it_behaves_like 'a common stateful model'
end
