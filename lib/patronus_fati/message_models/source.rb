module PatronusFati
  module MessageModels
    Source = CapStruct.new(
      :interface, :type, :username, :channel, :uuid, :packets, :hop, :velocity,
      :dwell, :hop_time_sec, :hop_time_usec
    )
    Source.set_data_filter(:channel, :dwell, :hop_time_sec, :hop_time_usec,
                           :hop, :packets, :velocity) { |val| val.to_i }
  end
end
