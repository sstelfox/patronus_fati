require 'spec_helper'

RSpec.describe 'DataModels::AccessPoint' do
  subject { PatronusFati::DataModels::AccessPoint }

  let(:unsaved_instance) { subject.new(bssid: '12:34:56:00:00:01', type: 'infrastructure', channel: 1) }
  let(:saved_instance)   { unsaved_instance.save }

  it { expect(subject).to have_property(:bssid) }
  it { expect(subject).to have_property(:type) }
  it { expect(subject).to have_property(:channel) }
  it { expect(subject).to have_property(:last_seen_at) }

  it { expect(subject).to have_many(:connections) }
  it { expect(subject).to have_many(:ssids) }

  it { expect(subject).to have_many(:clients).through(:connections) }
end
