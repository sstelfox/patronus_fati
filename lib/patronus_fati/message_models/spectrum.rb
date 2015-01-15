module PatronusFati
  module MessageModels
    Spectrum = CapStruct.new(
      :devname, :amp_offset_mdbm, :amp_res_mdbm, :rssi_max, :start_khz,
      :res_hz, :num_samples, :samples
    )
  end
end
