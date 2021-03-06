module PatronusFati::MessageProcessor::Alert
  include PatronusFati::MessageProcessor

  def self.process(obj)
    # Ignore the initial flood of cached data
    return unless PatronusFati.past_initial_flood?

    PatronusFati.event_handler.event(:alert, :new, process_obj(obj))

    nil
  end

  def self.process_obj(obj)
    {
      created_at: obj[:sec],
      type: obj[:header],
      message: obj[:text],

      source: obj[:source],
      destination: obj[:dest],
      other: obj[:other]
    }
  end
end
