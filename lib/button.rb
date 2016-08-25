class Button
  include Celluloid
  include Celluloid::Notifications

  STICKY = 1..10

  attr_reader :index, :row, :column

  def initialize(index, row, column)
    @index, @row, @column = index, row, column
    @down = false
  end

  def down!
    @down = true
    if @timer
      @timer.reset
    else
      @timer = after(0.15) do
        publish 'button:up', @index
        on! if STICKY.include?(index)
        @down = false
        @timer = nil
      end
    end
  end

  def down?
    !!@down
  end

  def on?
    down? || !!@on
  end

  def on!
    @on = true
  end

  def off!
    @on = false
  end

end