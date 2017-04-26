require 'spec_helper'

RSpec.describe(PatronusFati::DataModels::Connection) do
  subject { described_class.new('00:00:00:00:00:00', '34:34:34:34:34:34') }

  it_behaves_like 'a common stateful model'
end
