require 'spec_helper'

RSpec.describe(PatronusFati::DataModels::AccessPoint) do
  subject { described_class.new('66:77:88:99:aa:bb') }

  it_behaves_like 'a common stateful model'

  context '#active_ssids'
  context '#add_client'
  context '#announce_changes'
  context '#cleanup_ssids'
  context '#diagnostic_data'
  context '#full_state'
  context '#initialize'
  context '#mark_synced'
  context '#remove_client'

  context '#track_ssid' do
    let(:valid_ssid_data) { { essid: 'test' } }

    it 'should create a new SSID instance if one doesn\'t already exist' do
      expect(subject.ssids).to be_empty
      expect { subject.track_ssid(valid_ssid_data) }.to change { subject.ssids }
    end

    it 'should mark the SSID as visible' do
      ssid_dbl = double(PatronusFati::DataModels::Ssid)
      pres_dbl = double(PatronusFati::Presence)

      subject.ssids = { 'test' => ssid_dbl }

      allow(ssid_dbl).to receive(:dirty?)
      allow(ssid_dbl).to receive(:update)
      expect(ssid_dbl).to receive(:presence).and_return(pres_dbl)
      expect(pres_dbl).to receive(:mark_visible)

      subject.track_ssid(valid_ssid_data)
    end

    it 'should update the SSID with the attributes provided' do
      subject.track_ssid(valid_ssid_data)
      expect(subject.ssids['test'].presence).to receive(:mark_visible)
      subject.track_ssid(valid_ssid_data)
    end

    it 'should set the dirty children attribute if the SSID changed' do
      expect(subject.sync_flag?(:dirtyChildren)).to be_falsey
      subject.track_ssid(max_rate: 100)
      expect(subject.sync_flag?(:dirtyChildren)).to be_truthy
    end

    it 'should not set the dirty children attribute if the SSID info didn\'t change' do
      subject.track_ssid(valid_ssid_data)
      subject.mark_synced

      expect(subject.sync_flag?(:dirtyChildren)).to be_falsey
      subject.track_ssid(valid_ssid_data)
      expect(subject.sync_flag?(:dirtyChildren)).to be_falsey
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
      expect { subject.update(channel: 9) }
        .to change { subject.sync_status }
      expect(subject.sync_flag?(:dirtyAttributes)).to be_truthy
    end
  end

  context '#valid?' do
    it 'should be true when all required attributes are set' do
      subject.local_attributes = { bssid: 'something', channel: 4, type: 'adhoc' }
      expect(subject).to be_valid
    end

    it 'should not be valid when the channel is 0' do
      subject.local_attributes = { bssid: 'something', channel: 0, type: 'adhoc' }
      expect(subject).to_not be_valid
    end

    it 'should be false when missing a required attribute' do
      subject.local_attributes = { bssid: 'something', channel: 4 }
      expect(subject).to_not be_valid
    end
  end

  context '#vendor' do
    it 'should short circuit if no BSSID is available' do
      expect(Louis).to_not receive(:lookup)

      subject.update(bssid: nil)
      subject.vendor
    end

    it 'should use the Louis gem to perform it\'s lookup' do
      inst = 'test string'
      subject.update(bssid: inst)

      expect(Louis).to receive(:lookup).with(inst).and_return({})
      subject.vendor
    end

    it 'should default the long vendor name if it\'s available' do
      result = { 'long_vendor' => 'correct', 'short_vendor' => 'bad' }
      expect(Louis).to receive(:lookup).and_return(result)
      expect(subject.vendor).to eql('correct')
    end

    it 'should fallback on the short vendor name if long isn\'t available' do
      result = { 'short_vendor' => 'short' }
      expect(Louis).to receive(:lookup).and_return(result)
      expect(subject.vendor).to eql('short')
    end
  end
end
