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
  it { expect(subject).to have_many(:active_connections) }

  it { expect(subject).to have_many(:access_points).through(:connections) }
  it { expect(subject).to have_many(:current_access_points).through(:active_connections) }

  it { expect(subject).to belong_to(:mac) }

  it 'should associate to a MAC object before saving' do
    expect(unsaved_instance.mac).to be_nil
    unsaved_instance.save
    expect(unsaved_instance.mac).to be_instance_of(PatronusFati::DataModels::Mac)
  end
end
