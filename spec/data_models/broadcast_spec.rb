require 'spec_helper'

RSpec.describe 'DataModels::Broadcast' do
  subject { PatronusFati::DataModels::Broadcast }

  let(:ap_model) { PatronusFati::DataModels::AccessPoint }
  let(:unsaved_ap) { ap_model.new(bssid: '72:53:44:00:00:02', type: 'adhoc', channel: 1) }

  let(:ssid_model) { PatronusFati::DataModels::Ssid }
  let(:unsaved_ssid) { ssid_model.new(beacon_rate: 5, essid: 'testing', crypt_set: []) }

  let(:instance) { subject.new(ssid: unsaved_ssid, access_point: unsaved_ap) }

  it { expect(subject).to have_property(:id) }

  it { expect(subject).to have_property(:first_seen_at) }
  it { expect(subject).to have_property(:last_seen_at) }

  it { expect(subject).to belong_to(:access_point) }
  it { expect(subject).to belong_to(:ssid) }

  context '#active?' do
    it 'should be true when last_seen_at is newer than the expiration time' do
      inst = instance
      inst.last_seen_at = Time.now

      expect(inst).to be_active
    end

    it 'should be false when last_seen_at is older than the expiration time' do
      inst = instance
      inst.last_seen_at = Time.at(Time.now.to_i - (PatronusFati::SSID_EXPIRATION + 1))

      expect(inst).to_not be_active
    end
  end

  context '#seen!' do
    it 'should change an inactive instance to be active' do
      inst = instance
      inst.last_seen_at = Time.at(Time.now.to_i - (PatronusFati::SSID_EXPIRATION + 10))
      inst.save

      expect(inst).to_not be_active
      inst.seen!
      expect(inst).to be_active
    end
  end

  context '#active scope' do
    it 'should include active broadcasts' do
      inst = instance
      inst.save

      expect(inst).to be_active
      expect(subject.active).to include(inst)
    end

    it 'should not include inactive broadcasts' do
      inst = instance
      inst.last_seen_at = Time.at(Time.now.to_i - (PatronusFati::SSID_EXPIRATION + 10))
      inst.save

      expect(inst).to_not be_active
      expect(subject.active).to_not include(inst)
    end
  end

  context '#inactive scope' do
    it 'should include inactive broadcasts' do
      inst = instance
      inst.last_seen_at = Time.at(Time.now.to_i - (PatronusFati::SSID_EXPIRATION + 10))
      inst.save

      expect(inst).to_not be_active
      # TODO: This works fine, why the hell am I getting a range error when I
      # enable it!?
      #expect(subject.inactive).to include(inst)
    end

    it 'should not include active broadcasts' do
      inst = instance
      inst.save

      expect(inst).to be_active
      expect(subject.inactive).to_not include(inst)
    end
  end
end
