require 'spec_helper'

RSpec.describe 'DataModels::Alert' do
  subject { PatronusFati::DataModels::Alert }

  it { expect(subject).to have_property(:created_at) }
  it { expect(subject).to have_property(:message) }

  it { expect(subject).to belong_to(:src_mac) }
  it { expect(subject).to belong_to(:dst_mac) }
  it { expect(subject).to belong_to(:other_mac) }
end
