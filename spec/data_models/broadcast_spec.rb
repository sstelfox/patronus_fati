require 'spec_helper'

RSpec.describe 'DataModels::Broadcast' do
  subject { PatronusFati::DataModels::Broadcast }

  it { expect(subject).to have_property(:id) }

  it { expect(subject).to have_property(:first_seen_at) }
  it { expect(subject).to have_property(:last_seen_at) }

  it { expect(subject).to belong_to(:access_point) }
  it { expect(subject).to belong_to(:ssid) }
end
