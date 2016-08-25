class LightShow
  include Celluloid

  attr_accessor :palette
  attr_reader   :started_at

  def initialize(schedule, port)
    @schedule, @port = schedule, port
    @position  = 0
  end

  def start
    self.position = 0
    until done? do
      stream
    end
  end

  def stream
    # Catch up with current position
    while (@schedule.first[:position] <= @position) && @schedule.any?
      @schedule.shift
    end
    # Check that catch-up didn't throw away all events
    return if done?
    next_event_position = @schedule.first[:position].to_f
    if Time.now - @position_set_at >= next_event_position - @position
      payload = @schedule.first[:color]
      @port.write(payload)
      @schedule.shift
    end
    sleep 0.01
  end

  def position=(position)
    @position = position
    @position_set_at = Time.now
  end


  def done?
    @schedule.empty?
  end

  def started?
    !!@position_set_at
  end

end