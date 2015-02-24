module PatronusFati
  module NullTablePrefix
    def self.call(model_name)
      DataMapper::NamingConventions::Resource::UnderscoredAndPluralized.call(model_name.to_s.split('::').last)
    end
  end
end
