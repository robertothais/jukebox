# TODO (by 8/18)
# Playlists
# Shuffle (keep button on)
# End song (off all buttons)

# Nice to haves
# -------------
# Bucket based (stateless) event dispatcher
# Different chord -> index mappers (Markov Chain?, Poisson?)
# Recording button interactions (logging)

# This will kill the process on exception since portaudio
# isn't currently reliable to clean up after itself and make
# the audio device available when the just the actor dies.
# Remove once portaudio is made to exit cleanly on actor crashes.
# We can also not link the rest of the Jukebox to the player and exit
# Only when the player crashes
Celluloid.exception_handler { Kernel.exit!(1) }

class Jukebox
  include Celluloid
  include Celluloid::Notifications
  include Celluloid::Internals::Logger

  def initialize
    info 'Initializing Jukebox'
    @player = Player.new_link
    @button_panel = ButtonPanel.new_link if Machine.pi?
    @light_show_conductor = LightShowConductor.new_link
    subscribe 'song:pick_index', :on_play_index
    subscribe 'player:complete', :on_player_complete
    subscribe 'song:play', :on_play
    subscribe 'song:stop', :on_stop
    subscribe 'song:shuffle', :on_shuffle
  end

  def on_play_index(e, index)
    play(Song.find(Song.pluck(:id).sample))
  end

  def on_player_complete(e)
    # turn off all buttons
    info 'Playback complete'
    stop
  end

  def on_stop(e)
    info 'Going to stop song'
    stop
  end

  def on_play(e, song_id)
    song = Song.find(song_id)
    play(song)
  end

  def on_shuffle(e)
    info 'Going to shuffle'
    shuffle
  end

  def shuffle
    # make sure to light up button
  end

  def play(song)
    info "Going to play #{song.id}: #{song.title}"
    @player.stop
    @light_show_conductor.play(song) { @player.play(song) }
  end

  def stop
    @player.stop
    @light_show_conductor.stop(true)
  end
end