module PatronusFati
  class EventHandler
    def initialize
      @handlers = {}
    end

    def on(*types, &handler)
      Array(types).each do |t|
        @handlers[t.to_sym] ||= []
        @handlers[t.to_sym].push(handler)
      end
    end

    def event(asset_type, event_type, msg, optional = {})
      type = "#{asset_type.to_s}_#{event_type.to_s}".to_sym
      (Array(@handlers[:any]) & Array(@handlers[type])).each do |handler|
        handler.call(type, msg, optional)
      end
    end
  end
end
