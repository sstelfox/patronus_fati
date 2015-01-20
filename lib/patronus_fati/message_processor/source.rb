module PatronusFati
  module MessageProcessor
    module Source
      include MessageProcessor

      def self.process(obj)
        puts ('Got source message: %s' % obj.inspect)
      end
    end
  end
end
