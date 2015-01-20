module PatronusFati
  module MessageModels
    Error = CapStruct.new(:cmdid, :text)
    Error.set_data_filter(:cmdid) { |val| val.to_i }
  end
end
