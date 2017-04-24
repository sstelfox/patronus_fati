require 'spec_helper'

RSpec.describe(PatronusFati::DataModels::Client) do
  subject { described_class.new('00:11:22:33:44:55') }

  it_behaves_like 'a common stateful model'
end
