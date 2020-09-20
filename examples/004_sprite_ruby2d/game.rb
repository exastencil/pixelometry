require 'ruby2d'

# Ruby2D Window Configuration
set title: 'Ruby2D Sprite Example'

# Display instructions
label = Text.new 'Press Left or Right to walk', color: 'lime'
label.x = (Window.width - label.width) / 2
label.y = (Window.height - label.height) / 4

# Sprites are 96 x 192
# Since both are identical we can map them this way
sprites = %w[man.png woman.png].each_with_index.map do |path, i|
  Sprite.new(
    "#{__dir__}/../assets/#{path}",
    x: Window.width / 2 + (i.positive? ? -64 : 32), # X position
    y: Window.height / 2,                           # Y position
    width: 96 / 3,                                  # sprite width
    height: 192 / 4,                                # sprite height
    clip_width: 96 / 3,                             # Frame width
    clip_height: 192 / 4,                           # Frame height
    time: 150,                                      # Frame time in ms
    animations: {
      idle: 2..2,                                   # idle animation frames
      walk: 1..3                                    # walk animation frames
    }
  )
end

# Make the characters walk on left and right keys held
on :key_held do |event|
  case event.key
  when 'left'
    sprites.each do |sprite|
      sprite.play animation: :walk, loop: true
    end
  when 'right'
    sprites.each do |sprite|
      sprite.play animation: :walk, loop: true, flip: :horizontal
    end
  end
end

on :key_up do |event|
  close if event.key == 'escape'
  sprites.each do |sprite|
    sprite.play animation: :idle, loop: true, flip: event.key == 'right' ? :horizontal : false
  end
end

show
