module PatronusFati
  module MessageModels
    Plugin = CapStruct.new(
      :filename, :name, :version, :description, :unloadable, :root
    )
    Plugin.set_data_filter(:unloadable, :root) { |val| val.to_i }
  end
end
