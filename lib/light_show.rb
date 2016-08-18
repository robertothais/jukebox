class LightShow
  include Celluloid

  CALIBRATION_OFFSET = 0.005

  attr_accessor :position, :palette
  attr_reader   :started_at

  def initialize(schedule, palette, port)
    @schedule, @port = schedule, port
    @position  = 0
    @palette = palette
  end

  def start
    @started_at = Time.now
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
    next_event_time = @started_at + @schedule.first[:position].to_f
    if Time.now >= next_event_time - CALIBRATION_OFFSET
      color = @palette[@schedule.first[:color] % @palette.length]
      payload = [color].pack("H*")
      #payload = 3.times.map { rand(255) }.pack('C3')
      @port.write(payload)
      @schedule.shift
    end
    sleep 0.01
  end

  def done?
    @schedule.empty?
  end

  def started?
    !!@started_at
  end

end