require 'timeout'

class Player
  include Celluloid
  include Celluloid::Notifications
  include Celluloid::Internals::Logger

  finalizer :cleanup

  def initialize
    @audite = Audite.new
    @audite.events.on(:complete) do
      publish 'player:complete'
    end
    @audite.events.on(:position_change) do |pos|
      publish 'player:tick'
    end
    @audite.events.on(:toggle) do |playing|
      if playing
        publish 'player:started'
      end
    end
  end

  def play(song)
    stop if playing?
    @audite.load(song.path)
    @audite.start_stream
  end

  def stop
    if @audite
      @audite.stop_stream
      @audite.song_list.clear
    end
  end

  def cleanup
    info 'Cleaning up player'
    stop && @audite.stream.close
  end

  def playing?
    @audite.active
  end
end