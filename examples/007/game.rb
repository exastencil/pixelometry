# Load Ruby2D and Pixelometry
require 'pixelometry'

# Set up the structure of our game
define_game title: 'Pixelometry Sprite Example with Builtins' do
  # UI Layer
  create_scene renderer: ScreenSpaceRenderer do
    create_entity :label, text: 'A basic label'
    create_entity :label, text: 'A positioned label', x: 20, y: 50
    create_entity :label, text: 'A styled label', x: 20, y: 100, color: 'red'
    create_entity :label, text: 'A semi-transparent label', x: 20, y: 150, opacity: 0.5
  end
end
