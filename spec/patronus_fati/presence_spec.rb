require 'spec_helper'

RSpec.describe(PatronusFati::Presence) do
  context '#current_window' do
    # Test is dependent on the window length being one hour
    it 'should return the top of the hour' do
      cw = subject.current_window
      expect(Time.at(cw).min).to eql(0)
    end
  end

  context '#current_bit_offset' do
    it 'should return 0 at the beginnng of an hour' do
      allow(Time).to receive(:now).and_return(Time.at(1492110000))
      expect(subject.current_bit_offset).to eql(0)
    end

    it 'should return one less than the interval at the end of an hour' do
      allow(Time).to receive(:now).and_return(Time.at(1492109940))
      expect(subject.current_bit_offset).to eql(59)
    end

    it 'should return the appropriate bit in the middle of the hour' do
      allow(Time).to receive(:now).and_return(Time.at(1492108620))
      expect(subject.current_bit_offset).to eql(37)
    end
  end

  context '#rotate_presence' do
    let(:old_window) do
      subject.current_window - (2 * PatronusFati::Presence::WINDOW_LENGTH)
    end

    it 'should not modify the last_presence if we\'re still in the window' do
      subject.last_presence = 34
      subject.window_start = subject.current_window
      expect { subject.rotate_presence }.to_not change { subject.last_presence }
    end

    it 'should not modify the window_start if we\'re still in the window' do
      subject.last_presence = 34
      subject.window_start = subject.current_window
      expect { subject.rotate_presence }.to_not change { subject.window_start }
    end

    it 'should set the last_presence to the current_presence if the window changed' do
      subject.window_start = old_window
      subject.current_presence = 127
      expect { subject.rotate_presence }
        .to change { subject.last_presence }.from(0).to(127)
    end

    it 'should reset the current_presence to 0 if the window changed' do
      subject.window_start = old_window
      subject.current_presence = 127
      expect { subject.rotate_presence }
        .to change { subject.current_presence }.from(127).to(0)
    end

    it 'should update the window_start when the window changed' do
      subject.window_start = old_window
      subject.current_presence = 127
      expect { subject.rotate_presence }
        .to change { subject.window_start }.from(old_window).to(subject.current_window)
    end
  end

  context '#mark_visible' do
    it 'should trigger a window rotation' do
      expect(subject).to receive(:rotate_presence)
      subject.mark_visible
    end

    it 'should set the correct bit in the presence' do
      expect(subject).to receive(:current_bit_offset).and_return(5)
      expect { subject.mark_visible }
        .to change { subject.current_presence }.from(0).to(1 << 5)
    end

    it 'should not modify other bits in the presence' do
      expect(subject).to receive(:current_bit_offset).and_return(8)
      subject.current_presence = 1 << 5

      expect { subject.mark_visible }
        .to change { subject.current_presence }.from(1 << 5).to(1 << 5 | 1 << 8)
    end
  end

  context '#visible_at?' do
    let(:all_visible) do
      PatronusFati::Presence::WINDOW_INTERVALS.times.inject(0) { |obj, i| obj + (1 << i) }
    end

    it 'should return true if that interval was visible in the current window' do
      subject.current_presence = all_visible
      expect(subject.visible_at?(Time.now.to_i)).to be_truthy
    end

    it 'should return true if that interval was visible in the last window' do
      subject.last_presence = all_visible

      last_window = subject.current_window - PatronusFati::Presence::WINDOW_LENGTH
      expect(subject.visible_at?(last_window)).to be_truthy
    end

    it 'should be visible if only that one bit was set in the current window' do
      subject.current_presence = (1 << 8)
      time_check = subject.window_start + (8 * PatronusFati::Presence::INTERVAL_DURATION)
      expect(subject.visible_at?(time_check)).to be_truthy
    end

    it 'should be visible if only that one bit was set in the last window' do
      subject.last_presence = (1 << 8)
      time_check = subject.last_window_start + (8 * PatronusFati::Presence::INTERVAL_DURATION)
      expect(subject.visible_at?(time_check)).to be_truthy
    end

    it 'should return false if the time is in the future' do
      subject.last_presence = all_visible
      subject.current_presence = all_visible

      expect(subject.visible_at?(Time.now.to_i + 3600)).to be_falsey
    end

    it 'should return false if the time is to far in the past' do
      subject.last_presence = all_visible
      subject.current_presence = all_visible

      expect(subject.visible_at?(0)).to be_falsey
    end

    it 'should return false if the interval was not visible in the either window' do
      # 23 minutes / intervals ago...
      close_time = subject.current_window - (23 * 60)
      expect(subject.visible_at?(close_time)).to be_falsey
    end
  end

  context '#visible_since?' do
    it 'should not perform a check if the time is in the future' do
      expect(subject).to_not receive(:visible_at?)
      subject.visible_since?(Time.now.to_i + 7200)
    end

    it 'should return true when we have seen it since the requested time' do
      subject.mark_visible
      expect(subject.visible_since?(subject.last_window_start)).to be_truthy
      expect(subject.visible_since?(subject.window_start)).to be_truthy
    end

    it 'should return false when we haven\'t seen it since the requested time' do
      expect(subject.visible_since?(subject.last_window_start)).to be_falsey
      expect(subject.visible_since?(subject.window_start)).to be_falsey
    end

    it 'should handle checking the previous time window as well' do
      subject.last_presence = (1 << 23)
      expect(subject.visible_since?(subject.last_window_start)).to be_truthy
      expect(subject.visible_since?(subject.window_start)).to be_falsey
    end
  end
end
