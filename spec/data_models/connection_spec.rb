require 'spec_helper'

RSpec.describe 'DataModels::Connection' do
  subject { PatronusFati::DataModels::Connection }

  let(:client_model) { PatronusFati::DataModels::Client }
  let(:unsaved_client) { client_model.new(bssid: '11:22:33:00:00:00') }

  let(:ap_model) { PatronusFati::DataModels::AccessPoint }
  let(:unsaved_ap) { ap_model.new(bssid: '22:33:44:00:00:01', type: 'adhoc', channel: 6) }

  let(:instance) { subject.new(client: unsaved_client, access_point: unsaved_ap) }

  it { expect(subject).to have_property(:id) }

  it { expect(subject).to have_property(:connected_at) }
  it { expect(subject).to have_property(:disconnected_at) }

  it { expect(subject).to belong_to(:access_point) }
  it { expect(subject).to belong_to(:client) }

  context '#active scope' do
    it 'should include active connections' do
      inst = instance
      inst.save

      expect(inst).to be_active
      expect(subject.active).to include(inst)
    end

    it 'should not include inactive connections' do
      inst = instance
      inst.save
      inst.disconnect!

      expect(inst).to_not be_active
      expect(subject.active).to_not include(inst)
    end
  end

  context '#inactive scope' do
    it 'should not include active connections' do
      inst = instance
      inst.save

      expect(inst).to be_active
      expect(subject.inactive).to_not include(inst)
    end

    it 'should include inactive connections' do
      inst = instance
      inst.save
      inst.disconnect!

      expect(inst).to_not be_active
      expect(subject.inactive).to include(inst)
    end
  end

  context '#active?' do
    it 'should be true when a disconnection hasn\'t been registered' do
      inst = instance
      inst.disconnected_at = nil

      expect(inst).to be_active
    end

    it 'should be false when a disconnection has been registered' do
      inst = instance
      inst.disconnected_at = Time.now

      expect(inst).to_not be_active
    end
  end

  context '#disconnect!' do
    it 'should change an active instance to be inactive' do
      inst = instance
      inst.save

      expect(inst).to be_active
      inst.disconnect!
      expect(inst).to_not be_active
    end
  end
end
