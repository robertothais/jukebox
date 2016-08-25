class ButtonPanel
  include Celluloid
  include Celluloid::Notifications
  include Celluloid::Internals::Logger

  finalizer :cleanup

  BUTTON_PINS_ROW = [4, 17, 27, 22]
  BUTTON_PINS_COL = [23, 24, 25]

  LED_PINS_ROW = [ 5, 6, 7, 8]
  LED_PINS_COL = [ 9, 10 ,11 ]

  BUTTONS = [
    [1, 2, 3 ],
    [4, 5, 6 ],
    [7, 8, 9 ],
    [10,11,12]
  ]

  def initialize
    release_pins
    subscribe 'button:down', :on_button_down
    subscribe 'button:up',   :on_button_up
    @buttons = BUTTONS.map.with_index { |r, i| r.map.with_index { |c, j| Button.new(c, i, j) } }.flatten
    @last_button_on = @buttons.detect(&:on?)
    @monitor = future.monitor
    @renderer = future.render
  end

  def monitor
    @current_high_col = 0

    # monitor row pins
    BUTTONS.each_with_index do |row, row_index|
      PiPiper.after pin: BUTTON_PINS_ROW[row_index], direction: :in, pull: :down, goes: :high do |pin|
        Celluloid.publish 'button:down', BUTTONS[row_index][@current_high_col]
      end
    end

    # set all to low
    col_pins = BUTTON_PINS_COL.map{ |pin_number| PiPiper::Pin.new(pin: pin_number, direction: :out) }
    col_pins.each{ |pin| pin.off }

    loop do
      col_pins.each_with_index do |col_pin,col_index|
        @current_high_col = col_index
        col_pin.on
        sleep(0.01)
        col_pin.off
        @current_high_col = nil
      end
    end
  end

  def render
    row_pins = LED_PINS_ROW.map{ |pin_number| PiPiper::Pin.new(pin: pin_number, direction: :out) }
    col_pins = LED_PINS_COL.map{ |pin_number| PiPiper::Pin.new(pin: pin_number, direction: :out) }
    loop do
      button_on = @buttons.detect(&:on?)
      if @last_button_on != button_on
        row_pins.each { |pin| pin.off }
        col_pins.each { |pin| pin.off }
        @last_button_on = button_on
        next if button_on == nil
        col_pins.each_with_index do |pin, j|
          if button_on.column == j
            pin.off
          else
            pin.on
          end
        end
        row_pins.each_with_index do |pin, i|
          if button_on.row == i
            pin.on
          else
            pin.off
          end
        end
      end
      sleep(0.01)
    end
  end

  def on_button_down(_, index)
    info "Button #{index} went down"
    all_off!
    button_with_index(index).down!
  end

  def all_off!
    @buttons.each { |b| b.off! }
  end

  def on_button_up(_, index)
    info "Button #{index} was pressed"
    if index == 11
      shuffle_pressed
    elsif index == 12
      stop_pressed
    else
      song_button_pressed(index)
    end
  end

  def song_button_pressed(index)
    publish 'song:pick_index', index
  end

  def stop_pressed
    publish 'song:stop'
  end

  def shuffle_pressed
    publish 'song:shuffle'
  end

  def cleanup
    info 'Cleaning up button panel'
    all_off!
    @renderer.terminate
    @monitor.terminate
    release_pins
  end

  def button_with_index(index)
    @buttons.detect { |b| b.index == index }
  end

  def release_pins
    info 'Releasing all pins'
    ( BUTTON_PINS_ROW + BUTTON_PINS_COL + LED_PINS_COL + LED_PINS_ROW ).each do |pin|
      `echo #{pin} >/sys/class/gpio/unexport`
    end
  end

end