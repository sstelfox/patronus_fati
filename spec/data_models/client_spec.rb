require 'spec_helper'

RSpec.describe 'DataModels::Client' do
  subject { PatronusFati::DataModels::Client }

  let(:unsaved_instance) { subject.new(bssid: '12:34:56:00:00:02') }
  let(:saved_instance)   { unsaved_instance.save }

  it { expect(subject).to have_property(:id) }
  it { expect(subject).to have_property(:bssid) }
  it { expect(subject).to have_property(:last_seen_at) }

  it { expect(subject).to have_many(:probes) }

  it { expect(subject).to have_many(:connections) }
  it { expect(subject).to have_many(:access_points).through(:connections) }
end
