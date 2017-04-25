RSpec.shared_examples_for('a common stateful model') do
  context 'class methods' do
    # Helper to ensure tests don't interfere with each other
    before(:each) do
      described_class.instance_variable_set(:@instances, nil)
    end

    context '#[]' do
      it 'should create a new instance when the key doesn\'t exist' do
        expect { described_class['test'] }.to change { described_class.instances.count }.from(0).to(1)
        expect(described_class['test']).to be_instance_of(described_class)
      end

      it 'should return an existing instance when the key already exists' do
        dbl = double(described_class)
        described_class.instances['just^keyed'] = dbl
        expect(described_class['just^keyed']).to eq(dbl)
      end
    end

    context '#exists?' do
      it 'should be true when an instance matching the key exists' do
        described_class.instances['test'] = double(described_class)
        expect(described_class.exists?('test')).to be_truthy
      end

      it 'should be false when there is no instance matching the key' do
        expect(described_class.exists?('other')).to be_falsey
      end
    end

    context '#instances' do
      it 'should default to an empty hash' do
        expect(described_class.instances).to be_kind_of(Hash)
        expect(described_class.instances).to be_empty
      end
    end
  end

  context '#active?' do
    it 'should use it\'s expiration time against the presence instance' do
      expect(described_class).to receive(:current_expiration_threshold).and_return(137)
      expect(subject.presence).to receive(:visible_since?).with(137)

      subject.active?
    end

    it 'should pass the presence result back' do
      expect(subject.presence).to receive(:visible_since?).and_return(false)
      expect(subject.active?).to be_falsey

      expect(subject.presence).to receive(:visible_since?).and_return(true)
      expect(subject.active?).to be_truthy
    end

    it 'should have an expiration time' do
      expect(described_class).to respond_to(:current_expiration_threshold)
      expect(described_class.current_expiration_threshold).to be_kind_of(Numeric)
    end

    it 'should have an expiration in the past' do
      expect(described_class.current_expiration_threshold).to be <= Time.now.to_i
    end
  end

  context '#data_dirty?' do
    it 'should be false when no status flags have been set' do
      subject.sync_status = PatronusFati::SYNC_FLAGS[:unsynced]
      expect(subject.data_dirty?).to be_falsey
    end

    it 'should be false when only sync status flags are set' do
      subject.sync_status = PatronusFati::SYNC_FLAGS[:syncedOffline]
      expect(subject.data_dirty?).to be_falsey

      subject.sync_status = PatronusFati::SYNC_FLAGS[:syncedOnline]
      expect(subject.data_dirty?).to be_falsey
    end

    it 'should be true when the attributes have been marked dirty' do
      subject.sync_status = PatronusFati::SYNC_FLAGS[:dirtyAttributes]
      expect(subject.data_dirty?).to be_truthy
    end

    it 'should be true when a child has been marked dirty' do
      subject.sync_status = PatronusFati::SYNC_FLAGS[:dirtyChildren]
      expect(subject.data_dirty?).to be_truthy
    end
  end

  context '#dirty?' do
    it 'should be dirty when it\'s new' do
      expect(subject).to receive(:new?).and_return(true)

      expect(subject.dirty?).to be_truthy
    end

    it 'should be dirty if data has changed' do
      expect(subject).to receive(:new?).and_return(false)
      expect(subject).to receive(:data_dirty?).and_return(true)

      expect(subject.dirty?).to be_truthy
    end

    it 'should be dirty if the sync status doesn\'t match or current status' do
      expect(subject).to receive(:new?).and_return(false)
      expect(subject).to receive(:data_dirty?).and_return(false)
      expect(subject).to receive(:status_dirty?).and_return(true)

      expect(subject.dirty?).to be_truthy
    end

    it 'should not be dirty when nothing has changed' do
      expect(subject).to receive(:new?).and_return(false)
      expect(subject).to receive(:data_dirty?).and_return(false)
      expect(subject).to receive(:status_dirty?).and_return(false)

      expect(subject.dirty?).to be_falsey
    end
  end

  context '#mark_synced' do
    it 'should set the sync status to syncedOnline when active' do
      expect(subject).to receive(:active?).and_return(true)
      expect { subject.mark_synced }
        .to change { subject.sync_flag?(:syncedOnline) }.from(false).to(true)
    end

    it 'should set the sync status to syncedOffline when not active' do
      expect(subject).to receive(:active?).and_return(false)
      expect { subject.mark_synced }
        .to change { subject.sync_flag?(:syncedOffline) }.from(false).to(true)
    end

    it 'should clear the dirty attribute flags' do
      subject.set_sync_flag(:dirtyAttributes)
      expect { subject.mark_synced }
        .to change { subject.sync_flag?(:dirtyAttributes) }.from(true).to(false)

      subject.set_sync_flag(:dirtyChildren)
      expect { subject.mark_synced }
        .to change { subject.sync_flag?(:dirtyChildren) }.from(true).to(false)
    end
  end

  context 'new?' do
    it 'should be true when unsynced' do
      expect(subject.sync_status).to eql(PatronusFati::SYNC_FLAGS[:unsynced])
      expect(subject.new?).to be_truthy
    end

    it 'should be false when syncedOnline is set' do
      subject.set_sync_flag(:syncedOnline)
      expect(subject.new?).to be_falsey
    end

    it 'should be false when syncedOffline is set' do
      subject.set_sync_flag(:syncedOffline)
      expect(subject.new?).to be_falsey
    end

    it 'should be true when just the dirty data attributes are set' do
      expect(subject.sync_status).to eql(PatronusFati::SYNC_FLAGS[:unsynced])

      subject.set_sync_flag(:dirtyAttributes)
      subject.set_sync_flag(:dirtyChildren)

      expect(subject.new?).to be_truthy
    end
  end

  context '#presence' do
    it { expect(subject).to respond_to(:presence) }
    it { expect(subject.presence).to be_instance_of(PatronusFati::Presence) }
  end

  context '#set_sync_flag' do
    it 'should not change the value when it\'s already set' do
      subject.set_sync_flag(:syncedOnline)
      expect { subject.set_sync_flag(:syncedOnline) }
        .to_not change { subject.sync_status }
    end

    it 'should set the flag if it\'s not already set' do
      expect(subject.sync_flag?(:dirtyAttributes)).to be_falsey
      subject.set_sync_flag(:dirtyAttributes)
      expect(subject.sync_flag?(:dirtyAttributes)).to be_truthy
    end

    it 'should not change other flags when being set' do
      subject.set_sync_flag(:dirtyChildren)
      subject.set_sync_flag(:syncedOnline)

      expect(subject.sync_flag?(:dirtyChildren)).to be_truthy
    end
  end

  context '#status_dirty?' do
    it 'should be true when inactive and marked as active' do
      expect(subject).to receive(:active?).and_return(false)
      subject.set_sync_flag(:syncedOnline)
      expect(subject.status_dirty?).to be_truthy
    end

    it 'should be true when active and marked as inactive' do
      expect(subject).to receive(:active?).and_return(true)
      subject.set_sync_flag(:syncedOffline)
      expect(subject.status_dirty?).to be_truthy
    end

    it 'should be false when status and marking are active' do
      expect(subject).to receive(:active?).and_return(true)
      subject.set_sync_flag(:syncedOnline)
      expect(subject.status_dirty?).to be_falsey
    end

    it 'should be false when status and marking are inactive' do
      expect(subject).to receive(:active?).and_return(false)
      subject.set_sync_flag(:syncedOffline)
      expect(subject.status_dirty?).to be_falsey
    end
  end

  context '#sync_flag?' do
    it 'should be true when the provided flag is set' do
      expect { subject.set_sync_flag(:dirtyAttributes) }
        .to change { subject.sync_flag?(:dirtyAttributes) }.from(false).to(true)
    end

    it 'should be false when the provided flag isn\'t set' do
      subject.sync_status = 0
      expect(subject.sync_flag?(:dirtyChildren)).to be_falsey
    end

    it 'should be false when just another flag is set' do
      subject.sync_status = 0
      subject.set_sync_flag(:dirtyAttributes)
      expect(subject.sync_flag?(:syncedOffline)).to be_falsey
    end
  end
end
