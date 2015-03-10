module PatronusFati
  class EventHandler
    def handlers
      @handlers ||= {}
    end

    def handlers_for(asset_type, event_type)
      handlers[asset_type] ||= (asset_type == :any ? [] : {})
      Array(handlers[:any]) | Array(handlers[asset_type][:any]) | Array(handlers[asset_type][event_type])
    end

    def on(asset_type, event_type = :any, &handler)
      if asset_type == :any
        handlers[:any] ||= []
        handlers[:any].push(handler)
      else
        handlers[asset_type] ||= {}
        handlers[asset_type][event_type] ||= []
        handlers[asset_type][event_type].push(handler)
      end
    end

    def event(asset_type, event_type, msg, optional = {})
      handlers_for(asset_type, event_type).each { |h| h.call(asset_type, event_type, msg, optional) }
    end
  end
end
