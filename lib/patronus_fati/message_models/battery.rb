module PatronusFati
  module MessageModels
    Battery = CapStruct.new(:percentage, :charging, :ac, :remaining)
    Battery.set_data_filter(:percentage, :charging, :ac, :remaining) { |val| val.to_i }
  end
end
