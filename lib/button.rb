class Button
  include Celluloid
  include Celluloid::Notifications

  attr_reader :index, :row, :column

  def initialize(index, row, column)
    @index, @row, @column = index, row, column
    @down = false
  end

  def down
    @down = true
    if @timer
      @timer.reset
    else
      @timer = after(0.15) do
        @down = false
        @timer = nil
        publish 'button:up', @index
      end
    end
  end

  def down?
    !!@down
  end

  def on?
    down? || !!@on
  end

end