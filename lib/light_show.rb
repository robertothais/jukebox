class LightShow
  include Celluloid

  CALIBRATION_OFFSET = 0.005

  attr_accessor :palette
  attr_reader   :started_at

  def initialize(schedule, palette, port)
    @schedule, @port = schedule, port
    @position  = 0
    @palette = palette
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
      color = @palette[@schedule.first[:color] % @palette.length]
      payload = [color].pack("H*")
      #payload = 3.times.map { rand(255) }.pack('C3')
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
    !!@started_at
  end

end