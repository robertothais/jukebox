# TODO (by 8/18)
# Playlists
# Button lights
# Figure out buttons getting stuck, fix same button.
# Arduino code:
# - Ambient + chord mode
# - Chord mode starting from top
# - Low mode/startup shwoosh
# Event logging

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
    @player = Player.new_link
    @button_panel = ButtonPanel.new_link if Machine.pi?
    @light_show_conductor = LightShowConductor.new_link
    subscribe 'song:pick_index', :on_play_index
    subscribe 'song:play', :on_play
    subscribe 'song:stop', :on_stop
    subscribe 'song:shuffle', :on_shuffle
  end

  def on_play_index(e, index)
    play(Song.find(Song.pluck(:id).sample))
  end

  def on_play(e, song_id)
    song = Song.find(song_id)
    play(song)
  end

  def on_shuffle(e)
    shuffle
  end

  def on_stop(e)
    stop
  end

  def shuffle
    info 'Evryday I\'m Shuffling!'
  end

  def play(song)
    info "Will now play #{song.id}: #{song.title}"
    @light_show_conductor.play(song)
    @player.play(song)
  end

  def stop
    @player.stop
    @light_show_conductor.stop
  end
end