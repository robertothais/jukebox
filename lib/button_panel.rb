class ButtonPanel
  include Celluloid
  include Celluloid::Notifications

  def song_button_pressed(number)
    publish 'song:pick', number
  end

  def stop_pressed
    publish 'song:stop'
  end

  def shuffle_pressed
    # pick song
    publish 'song:pick', number
  end

end