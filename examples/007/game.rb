# Load Ruby2D and Pixelometry
require 'pixelometry'

require "#{__dir__}/fonts/terminus"

# Set up the structure of our game
define_game title: 'Pixelometry Sprite Example with Builtins' do
  # UI Layer
  create_scene renderer: ScreenSpaceRenderer do
    create_entity :label, text: 'A basic label'
    create_entity :label, text: 'A positioned label', x: 20, y: 50
    create_entity :label, text: 'A styled label', x: 20, y: 100, color: 'red'
    create_entity :label, text: 'A semi-transparent label', x: 20, y: 150, opacity: 0.8

    create_entity :label, text: 'A bitmap font with color', x: 20, y: 200, color: 'lime', font: :terminus
    create_entity :label, text: 'A bitmap font with opacity', x: 20, y: 220, color: 'yellow', opacity: 0.6, font: :terminus

    whacky_text = create_entity(
      :label,
      text: "Let's  go  a  little  crazy!",
      x: 20, y: 250,
      color: 'random',
      font: :terminus
    )

    text_reveal = create_entity(
      :label,
      text: "I bet you can't wait to hear what I have to say...",
      x: 20, y: 270,
      color: 'orange',
      opacity: 0.0,
      font: :terminus
    )

    each_frame do
      next unless Window.frames % 5 == 0

      whacky_text.text_object.each do |sprite|
        sprite.y = rand(249..251)
        sprite.color = 'random'
      end

      next if Window.frames > text_reveal.text.size * 5

      text_reveal.text_object[0..(Window.frames / 5)].each { |sprite| sprite.opacity = 1.0 }
    end
  end
end
