module PatronusFati
  module MessageModels
    Time = CapStruct.new(:timesec)
    Time.set_data_filter(:timesec) { |val| val.to_i }
  end
end
