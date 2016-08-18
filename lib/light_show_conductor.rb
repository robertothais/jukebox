class LightShowConductor
  include Celluloid
  include Celluloid::Notifications
  include Celluloid::Internals::Logger

  def initialize
    set_port
    subscribe 'player:started', :on_player_started
    subscribe 'player:tick',    :on_player_tick
  end

  def play(song)
    stop if playing?
    # Retry port if we're on the raspberry pi
    set_port if @port.is_a?(DummyPort) && Machine.pi?
    @show = LightShow.new_link(event_schedule_for(song.chords), palette, @port)
  end

  def on_player_started(_)
    @show.start if ready?
  end

  def on_player_tick(_, position)
    @show.position = position if playing?
  end

  def stop
    @show.terminate if has_show?
    @show = nil
  end

  def has_show?
    @show && @show.alive?
  end

  def palette
    %w(FA6900 69D2E7 E0E4CC FA5A46)
  end

  def playing?
    has_show? && @show.started?
  end

  def ready?
    has_show? && !@show.started?
  end

  def set_port
    port_str  = detect_port
    baud_rate = 9600
    data_bits = 8
    stop_bits = 1
    parity    = SerialPort::NONE
    @port = if port_str
      SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)
    else
      DummyPort.new
    end
  end

  def detect_port
    connected_ports = Machine.connected_ports

    if connected_ports.empty?
      warn 'No matching port found!  Please connect the Arduino, specify explicitly or update the serial ports config.'
    end

    if connected_ports.size > 1
      warn "Multiple valid ports found: #{connected_ports.inspect}.  Please specify which one, or update the serial ports config."
    end

    if connected_ports.size == 1
      info "Detected Arduino at #{connected_ports.first}"
      connected_ports.first
    else
      warn 'Using dummy port'
      nil
    end
  end

  def event_schedule_for(events)
    colors = colors_for(events)
    events.map do |event|
      {
        position: event['f'],
        chord:    event['chord'],
        color:    colors[event['c']]
      }
    end
  end

  def colors_for(chords)
    chords = chords.map { |x| x['c'] }
    collisions = {}
    chords[0..-2].zip(chords[1..-1]).map do |currentEv, nextEv|
      next if currentEv == nextEv
      collision = [currentEv, nextEv].sort
      collisions[collision] ||= 0
      collisions[collision] += 1
    end

    retval = {}
    index = 0

    collisions_sorted = Hash[collisions.to_a.sort_by(&:last).reverse]

    collisions_sorted.each do |these_chords, _count|
      unless retval.key?(these_chords[0])
        retval[these_chords[0]] = index
        index += 1
      end

      unless retval.key?(these_chords[1])
        retval[these_chords[1]] = index
        index += 1
      end
    end

    remaining_collisions = {}
    retval.to_a.group_by { |_chord, this_index| this_index % 5 }.each do |_index_mod, chord_map|
      these_chords = chord_map.map(&:first)
      next if these_chords.size == 1
      for i in 0..(these_chords.size - 1) do
        for j in (i + 1)..(these_chords.size - 1) do
          chord_collision = [these_chords[i], these_chords[j]].sort
          remaining_collisions[chord_collision] = collisions[chord_collision] unless collisions[chord_collision].nil?
        end
      end
    end
    retval
  end
end
