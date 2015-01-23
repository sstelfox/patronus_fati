module PatronusFati::DataObservers
  class AccessPointObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::AccessPoint

    before :save do
      puts self.inspect
    end
  end
end
