require 'spec_helper'

RSpec.describe(PatronusFati::DataModels::Client) do
  subject { described_class.new('00:11:22:33:44:55') }

  it_behaves_like 'a common stateful model'

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

      expect(PatronusFati.event_handler).to receive(:event).with(:client, :new, anything, anything)
      subject.announce_changes
    end

    it 'should emit a changed client event when dirty and synced as online' do
      subject.presence.mark_visible
      subject.mark_synced

      expect(subject).to receive(:dirty?).and_return(true)
      expect(subject).to receive(:valid?).and_return(true)

      expect(PatronusFati.event_handler).to receive(:event).with(:client, :changed, anything, anything)
      subject.announce_changes
    end

    it 'should emit a changed client event when dirty and synced as offline' do
      subject.mark_synced
      expect(subject.active?).to be_falsey

      subject.presence.mark_visible

      expect(subject).to receive(:valid?).and_return(true)
      expect(PatronusFati.event_handler).to receive(:event).with(:client, :changed, anything, anything)
      subject.announce_changes
    end

    it 'should emit an offline client event when the client becomes inactive' do
      subject.presence.mark_visible
      subject.mark_synced
      expect(subject.active?).to be_truthy

      expect(subject).to receive(:valid?).and_return(true)
      expect(subject).to receive(:active?).and_return(false).exactly(3).times

      expect(PatronusFati.event_handler).to receive(:event).with(:client, :offline, anything, anything)
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

    it 'should mark itself as synced when announced' do
      expect(subject).to receive(:dirty?).and_return(true)
      expect(subject).to receive(:valid?).and_return(true)
      expect(subject).to receive(:mark_synced)

      subject.announce_changes
    end

    it 'should announce the full state of the client with online syncs' do
      subject.presence.mark_visible
      subject.mark_synced

      data_sample = { data: 'test' }

      expect(subject).to receive(:dirty?).and_return(true)
      expect(subject).to receive(:valid?).and_return(true)
      expect(subject).to receive(:full_state).and_return(data_sample)

      expect(PatronusFati.event_handler).to receive(:event).with(:client, :changed, data_sample, anything)
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

      expect(PatronusFati.event_handler).to receive(:event).with(:client, :offline, min_data, anything)
      subject.announce_changes
    end

    it 'should announce the diagnostic data of the client' do
      sample_data = { content: 'diagnostic' }

      expect(subject).to receive(:dirty?).and_return(true)
      expect(subject).to receive(:valid?).and_return(true)
      expect(subject).to receive(:diagnostic_data).and_return(sample_data)

      expect(PatronusFati.event_handler).to receive(:event).with(:client, :offline, anything, sample_data)
      subject.announce_changes
    end
  end

  context '#add_access_point'
  context '#cleanup_probes'
  context '#full_state'
  context '#initialize'
  context '#remove_access_point'
  context '#track_probe'
  context '#update'
  context '#valid?'
  context '#vendor'
end
