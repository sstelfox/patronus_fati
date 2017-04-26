require 'spec_helper'

RSpec.describe(PatronusFati::DataModels::Client) do
  subject { described_class.new('00:11:22:33:44:55') }

  it_behaves_like 'a common stateful model'

  context '#add_access_point' do
    it 'should not add an access point more than once' do
      sample_mac = '33:33:33:44:44:44'
      subject.access_point_bssids = [ sample_mac ]

      expect { subject.add_access_point(sample_mac) }
        .to_not change { subject.access_point_bssids }
    end

    it 'should add an access point if it\'s not presently in the list' do
      sample_mac = '99:11:22:ff:23:00'

      expect(subject.access_point_bssids).to be_empty
      expect { subject.add_access_point(sample_mac) }
        .to change { subject.access_point_bssids }.from([]).to([sample_mac])
    end
  end

  context '#announce_changes' do
    before(:each) do
      PatronusFati::DataModels::AccessPoint.instance_variable_set(:@instances, nil)
      PatronusFati::DataModels::Client.instance_variable_set(:@instances, nil)
      PatronusFati::DataModels::Connection.instance_variable_set(:@instances, nil)
    end

    it 'should emit no events when the client isn\'t valid' do
      expect(subject).to receive(:dirty?).and_return(true)
      expect(subject).to receive(:valid?).and_return(false)

      expect(PatronusFati.event_handler).to_not receive(:event)
      subject.announce_changes
    end

    it 'should emit no events when the instance isn\'t dirty' do
      expect(subject).to receive(:dirty?).and_return(false)

      expect(PatronusFati.event_handler).to_not receive(:event)
      subject.announce_changes
    end

    it 'should emit a new client event when dirty and unsynced' do
      expect(subject).to receive(:dirty?).and_return(true)
      expect(subject).to receive(:valid?).and_return(true)
      subject.presence.mark_visible

      expect(PatronusFati.event_handler)
        .to receive(:event).with(:client, :new, anything, anything)
      subject.announce_changes
    end

    it 'should emit a changed client event when dirty and synced as online' do
      subject.presence.mark_visible
      subject.mark_synced

      expect(subject).to receive(:dirty?).and_return(true)
      expect(subject).to receive(:valid?).and_return(true)

      expect(PatronusFati.event_handler)
        .to receive(:event).with(:client, :changed, anything, anything)
      subject.announce_changes
    end

    it 'should emit a changed client event when dirty and synced as offline' do
      subject.mark_synced
      expect(subject.active?).to be_falsey

      subject.presence.mark_visible

      expect(subject).to receive(:valid?).and_return(true)
      expect(PatronusFati.event_handler)
        .to receive(:event).with(:client, :changed, anything, anything)
      subject.announce_changes
    end

    it 'should emit an offline client event when the client becomes inactive' do
      subject.presence.mark_visible
      subject.mark_synced
      expect(subject.active?).to be_truthy

      expect(subject).to receive(:valid?).and_return(true)
      expect(subject).to receive(:active?).and_return(false).exactly(3).times

      expect(PatronusFati.event_handler)
        .to receive(:event).with(:client, :offline, anything, anything)
      subject.announce_changes
    end

    it 'should reset the presence first_seen value when announced offline' do
      subject.presence.mark_visible
      subject.mark_synced
      expect(subject.active?).to be_truthy

      expect(subject).to receive(:valid?).and_return(true)
      expect(subject).to receive(:active?).and_return(false).exactly(3).times

      expect { subject.announce_changes }
        .to change { subject.presence.first_seen }.to(nil)
    end

    it 'should remove itself from access points as a connected client when announced offline' do
      bssid = 'fa:eb:dc:45:23:67'
      dbl = double(PatronusFati::DataModels::AccessPoint)
      PatronusFati::DataModels::AccessPoint.instances[bssid] = dbl

      subject.presence.mark_visible
      subject.add_access_point(bssid)
      subject.mark_synced

      expect(dbl).to receive(:remove_client).with(subject.local_attributes[:mac])
      expect(subject).to receive(:active?).and_return(false).exactly(3).times

      subject.announce_changes
    end

    it 'should mark active connections with a lost link when announced offline' do
      bssid = 'fa:eb:dc:45:23:67'
      conn_key = "#{bssid}^#{subject.local_attributes[:mac]}"

      dbl = double(PatronusFati::DataModels::Connection)
      PatronusFati::DataModels::Connection.instances[conn_key] = dbl

      subject.presence.mark_visible
      subject.add_access_point(bssid)
      subject.mark_synced

      expect(dbl).to receive(:link_lost=).with(true)
      expect(subject).to receive(:active?).and_return(false).exactly(3).times

      subject.announce_changes
    end

    it 'short not be dirty after being synced' do
      expect(subject).to receive(:valid?).and_return(true)
      subject.update(channel: 8)

      expect { subject.announce_changes }.to change { subject.dirty? }.from(true).to(false)
    end

    it 'should announce the full state of the client with online syncs' do
      subject.presence.mark_visible
      subject.mark_synced

      data_sample = { data: 'test' }

      expect(subject).to receive(:dirty?).and_return(true)
      expect(subject).to receive(:valid?).and_return(true)
      expect(subject).to receive(:full_state).and_return(data_sample)

      expect(PatronusFati.event_handler)
        .to receive(:event).with(:client, :changed, data_sample, anything)
      subject.announce_changes
    end

    it 'should announce a minimal state of the client with offline syncs' do
      subject.presence.mark_visible
      subject.mark_synced

      expect(subject).to receive(:valid?).and_return(true)
      expect(subject).to receive(:active?).and_return(false).exactly(3).times

      expect(subject.presence).to receive(:visible_time).and_return(1234)
      min_data = {
        'bssid' => subject.local_attributes[:mac],
        'uptime' => 1234
      }

      expect(PatronusFati.event_handler)
        .to receive(:event).with(:client, :offline, min_data, anything)
      subject.announce_changes
    end

    it 'should announce the diagnostic data of the client' do
      sample_data = { content: 'diagnostic' }

      expect(subject).to receive(:dirty?).and_return(true)
      expect(subject).to receive(:valid?).and_return(true)
      expect(subject).to receive(:diagnostic_data).and_return(sample_data)

      expect(PatronusFati.event_handler)
        .to receive(:event).with(:client, :offline, anything, sample_data)
      subject.announce_changes
    end
  end

  context '#cleanup_probes' do
    let(:probe) { PatronusFati::Presence.new }

    it 'should not modify the children flag when there are no probes' do
      expect(subject.probes).to be_empty
      expect { subject.cleanup_probes }.to_not change { subject.sync_status }
    end

    it 'should not modify the children flag when there is only active probes' do
      probe.mark_visible
      subject.probes = { 'probe key' => probe }
      expect { subject.cleanup_probes }.to_not change { subject.sync_status }
    end

    it 'should modify the children flag when there is a dead probe' do
      expect(probe).to be_dead
      subject.probes = { 'NETGEAR32' => probe }
      expect { subject.cleanup_probes }
        .to change { subject.sync_flag?(:dirtyChildren) }.from(false).to(true)
    end

    it 'should remove all dead probes from the list' do
      expect(probe).to be_dead
      subject.probes = { 'linksys' => probe }
      expect { subject.cleanup_probes }.to change { subject.probes }.to({})
    end
  end

  context '#full_state' do
    it 'should return a hash' do
      expect(subject.full_state).to be_kind_of(Hash)
    end

    it 'should include the keys expected by pulse' do
      [:active, :bssid, :channel, :connected_access_points, :probes, :vendor].each do |k|
        expect(subject.full_state.key?(k)).to be_truthy
      end
    end
  end

  context '#initialize' do
    it 'should initialize probes to an empty hash' do
      expect(subject.probes).to eql({})
    end

    it 'should initialize the local attributes with the client\'s mac' do
      expect(subject.local_attributes.keys).to eql([:mac])
      expect(subject.local_attributes[:mac]).to_not be_nil
    end

    it 'should initialize the APs it\'s connected to, to an empty array' do
      expect(subject.access_point_bssids).to eql([])
    end
  end

  context '#remove_access_point' do
    it 'should make no change if the the bssid isn\'t present' do
      subject.access_point_bssids = [ '78:2b:11:ae:00:12' ]
      expect { subject.remove_access_point('00:11:22:33:44:55') }
        .to_not change { subject.access_point_bssids }
    end

    it 'should remove just the bssid provided when it is present' do
      test_mac = '00:11:22:33:44:55'
      subject.access_point_bssids = [ '78:2b:11:ae:00:12', test_mac ]

      expect { subject.remove_access_point(test_mac) }
        .to change { subject.access_point_bssids }
      expect(subject.access_point_bssids).to_not include(test_mac)
    end
  end

  context '#track_probe' do
    it 'should not change anything when provided a nil value' do
      expect { subject.track_probe(nil) }.to_not change { subject.probes }
    end

    it 'should not change anything when provided an empty string' do
      expect { subject.track_probe('') }.to_not change { subject.probes }
    end

    it 'should track new probes as a new presence instance' do
      subject.track_probe('test')
      expect(subject.probes['test']).to be_instance_of(PatronusFati::Presence)
      expect(subject.probes['test']).to_not be_dead
    end

    it 'should mark existing probes as visisble' do
      dbl = double(PatronusFati::Presence)
      subject.probes['pineapple'] = dbl
      expect(dbl).to receive(:mark_visible)
      subject.track_probe('pineapple')
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
      expect { subject.update(channel: 5) }
        .to change { subject.sync_status }
      expect(subject.sync_flag?(:dirtyAttributes)).to be_truthy
    end
  end

  context '#valid?' do
    it 'should be true when all required attributes are set' do
      subject.local_attributes = { mac: 'testing' }
      expect(subject).to be_valid
    end

    it 'should be false when missing a required attribute' do
      subject.local_attributes.delete(:mac)
      expect(subject).to_not be_valid
    end
  end

  context '#vendor' do
    it 'should short circuit if no MAC is available' do
      expect(Louis).to_not receive(:lookup)

      subject.update(mac: nil)
      subject.vendor
    end

    it 'should use the Louis gem to perform it\'s lookup' do
      inst = 'test string'
      subject.update(mac: inst)

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
