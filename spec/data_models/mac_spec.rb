require 'spec_helper'

RSpec.describe 'DataModels::Mac' do
  subject { PatronusFati::DataModels::Mac }

  let(:unsaved_instance) { subject.new(mac: '00:12:34:00:00:00') }
  let(:saved_instance)   { unsaved_instance.save }

  it { expect(subject).to have_property(:mac) }
  it { expect(subject).to have_property(:vendor) }

  it { expect(subject).to have_many(:access_points) }
  it { expect(subject).to have_many(:clients) }

  it { expect(subject).to have_many(:dst_alerts) }
  it { expect(subject).to have_many(:other_alerts) }
  it { expect(subject).to have_many(:src_alerts) }

  # This is a tad bit annoying, data mapper generates Ruby warnings about
  # uninitialized instance variables.
  it 'should set the vendor on the MAC object before saving' do
    expect(unsaved_instance.vendor).to be_nil
    unsaved_instance.save
    expect(unsaved_instance.vendor).to_not be_nil
  end
end
