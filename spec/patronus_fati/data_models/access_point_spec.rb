require 'spec_helper'

RSpec.describe(PatronusFati::DataModels::AccessPoint) do
  subject { described_class.new('66:77:88:99:aa:bb') }

  it_behaves_like 'a common stateful model'

  context '#active_ssids' do
    it 'should return a hash' do
      expect(subject.active_ssids).to be_kind_of(Hash)
    end

    it 'should not include inactive SSIDs' do
      ssid = double(PatronusFati::DataModels::Ssid)
      expect(ssid).to receive(:active?).and_return(false)

      subject.ssids = { tmp: ssid }
      expect(subject.active_ssids.values).to_not include(ssid)
    end

    it 'should include active SSIDs' do
      ssid = double(PatronusFati::DataModels::Ssid)
      expect(ssid).to receive(:active?).and_return(true)

      subject.ssids = { tmp: ssid }
      expect(subject.active_ssids.values).to include(ssid)
    end
  end

  context '#add_client'
  context '#announce_changes'
  context '#cleanup_ssids'

  context '#diagnostic_data' do
    it 'should include all SSID diagnostic data' do
      ssid_dbl = double(PatronusFati::DataModels::Ssid)
      expect(ssid_dbl).to receive(:diagnostic_data).and_return(:datum)
      subject.ssids = { tmp: ssid_dbl }
      expect(subject.diagnostic_data[:ssids]).to eql({tmp: :datum})
    end
  end

  context '#full_state' do
    it 'should return a hash' do
      expect(subject.full_state).to be_kind_of(Hash)
    end

    it 'should include the keys expected by pulse' do
      subject.update(channel: 45, type: 'adhoc')
      [:active, :bssid, :channel, :connected_clients, :ssids, :type, :vendor].each do |k|
        expect(subject.full_state.key?(k)).to be_truthy
      end
    end

    it 'should include the attributes of active ssids' do
      ssid_dbl = double(PatronusFati::DataModels::Ssid)
      expect(subject).to receive(:active_ssids).and_return({ pnt: ssid_dbl })
      expect(ssid_dbl).to receive(:local_attributes).and_return('data')
      expect(subject.full_state[:ssids]).to eql(['data'])
    end
  end

  context '#initialize' do
    it 'should set the local attributes to an appropriate hash' do
      subject = described_class.new('12:23:34:45:56:67')
      expect(subject.local_attributes).to eql(bssid: '12:23:34:45:56:67')
    end

    it 'should initialize client_macs to an empty array' do
      expect(subject.client_macs).to be_kind_of(Array)
      expect(subject.client_macs).to be_empty
    end

    it 'should initialize ssids to an empty hash' do
      expect(subject.ssids).to be_kind_of(Hash)
      expect(subject.ssids).to be_empty
    end
  end

  context '#mark_synced' do
    it 'should clear dirty flags' do
      subject.update(channel: 8)
      expect(subject.data_dirty?).to be_truthy
      expect { subject.mark_synced }
        .to change { subject.data_dirty? }.from(true).to(false)
    end

    it 'should call mark_synced on each SSID as well' do
      dbl = double(PatronusFati::DataModels::Ssid)
      subject.ssids = { test: dbl }

      expect(dbl).to receive(:mark_synced)
      subject.mark_synced
    end
  end

  context '#remove_client' do
    it 'should make no changes if the provided mac isn\'t present' do
      subject.client_macs = [ 'one' ]
      expect { subject.remove_client('test') }.to_not change { subject.client_macs }
    end

    it 'should remove only the provided mac if other macs are present' do
      subject.client_macs = [ 'a', 'b', 'c' ]
      subject.remove_client('b')

      expect(subject.client_macs).to eql(['a', 'c'])
    end
  end

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
