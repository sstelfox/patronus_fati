require 'spec_helper'

RSpec.describe(PatronusFati::DataModels::Ssid) do
  subject { described_class.new('BillWiTheScienceFi') }

  it_behaves_like 'a common stateful model'

  context '#full_state' do
    it 'should include all the local attributes'
    it 'should include the last time it was seen'
  end

  context '#initialize' do
    it 'should initialize the local attributes with the essid' do
      expect(subject.local_attributes.keys).to include(:essid)
      expect(subject.local_attributes[:essid]).to_not be_nil
    end

    it 'should initialize the local attributes with cloaked' do
      expect(subject.local_attributes.keys).to include(:cloaked)
    end

    it 'should initialize the cloaked attribute to false if an essid is provided' do
      expect(subject.local_attributes[:essid]).to_not be_nil
      expect(subject.local_attributes[:essid].size).to be > 0
      expect(subject.local_attributes[:cloaked]).to be_falsey
    end

    it 'should initialize the cloaked attribute to true if a nil essid is provided' do
      subject = described_class.new(nil)
      expect(subject.local_attributes[:cloaked]).to be_truthy
    end

    it 'should initialize the cloaked attribute to true if an empty essid is provided' do
      subject = described_class.new('')
      expect(subject.local_attributes[:cloaked]).to be_truthy
    end
  end

  context '#update' do
    it 'should not set invalid keys' do
      expect { subject.update(bad: 'key') }
        .to_not change { subject.local_attributes }
    end

    it 'shouldn\'t modify the sync flags on invalid keys' do
      expect { subject.update(other: 'key') }
        .to_not change { subject.sync_status }
    end

    it 'shouldn\'t modify the sync flags if the values haven\'t changed' do
      expect { subject.update(subject.local_attributes) }
        .to_not change { subject.sync_status }
    end

    it 'should set the dirty attribute flag when a value has changed' do
      expect { subject.update(max_rate: 5) }
        .to change { subject.sync_status }
      expect(subject.sync_flag?(:dirtyAttributes)).to be_truthy
    end
  end
end
