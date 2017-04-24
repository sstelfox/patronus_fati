require 'spec_helper'

RSpec.describe(PatronusFati::DataModels::AccessPoint) do
  subject { described_class.new('66:77:88:99:aa:bb') }

  it_behaves_like 'a common stateful model'
end
