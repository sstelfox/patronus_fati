module PatronusFati
  class NullObject < BasicObject
    def initialize(*args)
      puts "Placeholder object instantiated with arguments: #{args.inspect}"
    end

    def methods_missing(*args, &block)
      self
    end
  end
end
