require 'spec_helper'

RSpec.describe(PatronusFati::DataModels::Client) do
  subject { described_class.new('00:11:22:33:44:55') }

  it_behaves_like 'a common stateful model'

  context '#announce_changes' do
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

    it 'should emit a changed client event when dirty and synced as offline'
    it 'should emit an offline client event when the client becomes inactive'
    it 'should reset the presence first_seen value when announced offline'
    it 'should remove itself from access points as a connected client when announced offline'
    it 'should mark active connections with a lost link when announced offline'

    it 'should mark itself as synced when announced' do
      expect(subject).to receive(:dirty?).and_return(true)
      expect(subject).to receive(:valid?).and_return(true)
      expect(subject).to receive(:mark_synced)

      subject.announce_changes
    end

    it 'should announce the full state of the client with online syncs'
    it 'should announce a minimal state of the client with offline syncs'
    it 'should announce the diagnostic data of the client'
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
