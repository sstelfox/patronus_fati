require 'spec_helper'

RSpec.describe PatronusFati::DataModels::Connection do
  let(:ap_model) { PatronusFati::DataModels::AccessPoint }
  let(:client_model) { PatronusFati::DataModels::Client }

  let(:unsaved_ap) { ap_model.new(bssid: '22:33:44:00:00:01', type: 'adhoc', channel: 6) }
  let(:unsaved_client) { client_model.new(bssid: '11:22:33:00:00:00') }

  let(:instance) { described_class.new(client: unsaved_client, access_point: unsaved_ap) }

  it { expect(described_class).to have_property(:id) }

  it { expect(described_class).to have_property(:connected_at) }
  it { expect(described_class).to have_property(:disconnected_at) }

  it { expect(described_class).to belong_to(:access_point) }
  it { expect(described_class).to belong_to(:client) }

  context '#connected?' do
    it 'should be true when a disconnection hasn\'t been registered' do
      inst = instance
      inst.disconnected_at = nil

      expect(inst).to be_connected
    end

    it 'should be false when a disconnection has been registered' do
      inst = instance
      inst.disconnected_at = Time.now

      expect(inst).to_not be_connected
    end
  end

  context '#disconnect!' do
    it 'should change a connected instance to be disconnected' do
      inst = instance
      inst.save

      expect(inst).to be_connected
      inst.disconnect!
      expect(inst).to_not be_connected
    end
  end

  context '#connected scope' do
    it 'should include active connections' do
      inst = instance
      inst.save

      expect(described_class.connected).to include(inst)
    end

    it 'should not include disconnected connections' do
      inst = instance
      inst.save
      inst.disconnect!

      expect(described_class.connected).to_not include(inst)
    end
  end

  context '#disconnected scope' do
    it 'should not include disconnected connections' do
      inst = instance
      inst.save

      expect(inst).to be_connected
      expect(described_class.disconnected).to_not include(inst)
    end

    it 'should include disconnected connections' do
      inst = instance
      inst.save
      inst.disconnect!

      expect(inst).to_not be_connected
      expect(described_class.disconnected).to include(inst)
    end
  end
end
