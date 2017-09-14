require 'spec_helper'

RSpec.describe(PatronusFati::Presence) do
  context '#current_window_start' do
    # Test is dependent on the window length being one hour
    it 'should return the top of the hour' do
      cw = subject.current_window_start
      expect(Time.at(cw).min).to eql(0)
    end
  end

  context '#current_bit_offset' do
    it 'should return 1 at the beginnng of an hour' do
      allow(Time).to receive(:now).and_return(Time.at(1492110000))
      expect(subject.current_bit_offset).to eql(1)
    end

    it 'should return the interval at the end of an hour' do
      allow(Time).to receive(:now).and_return(Time.at(1492109940))
      expect(subject.current_bit_offset).to eql(60)
    end

    it 'should return the appropriate bit in the middle of the hour' do
      allow(Time).to receive(:now).and_return(Time.at(1492108620))
      expect(subject.current_bit_offset).to eql(38)
    end
  end

  context '#rotate_presence' do
    let(:old_window_start) do
      subject.current_window_start - (2 * PatronusFati::WINDOW_LENGTH)
    end

    it 'should not modify the last_presence if we\'re still in the window' do
      subject.window_start = subject.current_window_start
      expect { subject.rotate_presence }.to_not change { subject.last_presence }
    end

    it 'should not modify the window_start if we\'re still in the window' do
      subject.last_presence = 34
      subject.window_start = subject.current_window_start
      expect { subject.rotate_presence }.to_not change { subject.window_start }
    end

    it 'should set the last_presence to the current_presence if the window changed' do
      subject.window_start = old_window_start
      subject.current_presence.set_bit(23)
      expect { subject.rotate_presence }
        .to change { subject.last_presence.bit_set?(23) }.from(false).to(true)
    end

    it 'should reset the current_presence to 0 if the window changed' do
      subject.window_start = old_window_start
      subject.current_presence.set_bit(9)
      expect { subject.rotate_presence }
        .to change { subject.current_presence.bit_set?(9) }.from(true).to(false)
    end

    it 'should update the window_start when the window changed' do
      subject.window_start = old_window_start
      subject.current_presence.set_bit(8)
      expect { subject.rotate_presence }
        .to change { subject.window_start }.from(old_window_start).to(subject.current_window_start)
    end
  end

  context '#last_visible' do
    it 'should return nil if we haven\'t marked anything as visible' do
      expect(subject.last_visible).to be_nil
    end

    it 'should return the time when the last_visible is in the current window' do
      # Note: bit 1 == minute 0, this which is why these two numbers differ
      time = subject.current_window_start + (22 * PatronusFati::INTERVAL_DURATION)
      subject.current_presence.set_bit(23)
      expect(subject.last_visible).to eql(time)
    end

    it 'should return the time when the last_visisble is in the last window' do
      # Note: bit 1 == minute 0, this which is why these two numbers differ
      time = subject.last_window_start + (1 * PatronusFati::INTERVAL_DURATION)
      subject.last_presence.set_bit(2)
      expect(subject.last_visible).to eql(time)
    end
  end

  context '#mark_visible' do
    it 'should trigger a window rotation' do
      expect(subject).to receive(:rotate_presence)
      subject.mark_visible
    end

    it 'should set the correct bit in the presence' do
      expect(subject).to receive(:current_bit_offset).and_return(5)
      expect(subject.current_presence).to receive(:set_bit).with(5)
      subject.mark_visible
    end

    it 'should set the first_seen timestamp if it hasn\'t been seen yet' do
      expect { subject.mark_visible }.to change { subject.first_seen }.from(nil)
    end

    it 'should not modify the first_seen timestamp if it has already been set' do
      subject.first_seen = Time.now.to_i - 120
      expect { subject.mark_visible }.to_not change { subject.first_seen }
    end
  end

  context '#visible_since?' do
    it 'should return true when we have seen it since the requested time' do
      subject.mark_visible

      expect(subject.visible_since?(subject.last_window_start)).to be_truthy
      expect(subject.visible_since?(subject.current_window_start)).to be_truthy
    end

    it 'should return false when we haven\'t seen it since the requested time' do
      expect(subject.visible_since?(subject.last_window_start)).to be_falsey
      expect(subject.visible_since?(subject.current_window_start)).to be_falsey
    end

    it 'should handle checking the previous time window as well' do
      subject.last_presence.set_bit(23)
      expect(subject.visible_since?(subject.last_window_start)).to be_truthy
      expect(subject.visible_since?(subject.current_window_start)).to be_falsey
    end
  end
end
