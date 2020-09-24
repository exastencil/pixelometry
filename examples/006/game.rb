# Load Ruby2D and Pixelometry
require 'pixelometry'

# Since we will have two, let's define the template and reuse it
define_entity :character do
  # Positioned means it has x, y and z properties
  attribute :positioned, y: Game.height / 2

  # Which direction the sprite is facing
  attribute :directed, default: { x: 1 }

  # Combines the properties needed to render a sprite (sprite and asset_path)
  attribute :renderable, width: 96, height: 192

  # Indicates that the sprite is a sprite sheet, stores the animation state and animations
  # Also provides `play :animation` and `play_once :animation` on entity
  attribute :animated, default: :idle, width: 32, height: 48, duration: 150, animations: {
    idle: 1, # Just a frame to show
    walking: [0, 1, 2, 1], # A sequence of frames
    # Something a little fancier
    tempo: [
      { frame: 0, duration: 125 },
      { frame: 1, duration: 175 },
      { frame: 2, duration: 125 },
      { frame: 1, duration: 175 }
    ]
  }

  # Behavior to change direction and start walking on key press
  # on :key_down do |event|
  #   self.x_direction =  1 if event.key == 'left'
  #   self.x_direction = -1 if event.key == 'right'
  #   play :walking if %w[left right].include? event.key
  # end

  # Behavior to stop walking and idle on key release
  on :key_up do |event|
    play :idle if %w[left right].include? event.key
  end
end

# Set up the structure of our game
define_game title: 'Pixelometry Sprite Example with Builtins' do
  # World
  create_scene renderer: ScreenSpaceRenderer do
    create_entity :character, x: Game.width / 2 - 64, asset_path: "#{__dir__}/../assets/man.png" do
      on :key_down do |event|
        self.x_direction =  1 if event.key == 'left'
        self.x_direction = -1 if event.key == 'right'
        play :walking if %w[left right].include? event.key
      end
    end
    create_entity :character, x: Game.width / 2 + 32, asset_path: "#{__dir__}/../assets/woman.png" do
      on :key_down do |event|
        self.x_direction =  1 if event.key == 'left'
        self.x_direction = -1 if event.key == 'right'
        play :tempo if %w[left right].include? event.key
      end
    end
  end

  # UI Layer
  create_scene do
    # Display instructions (same as previous implementation)
    Text.new('Press Left or Right to walk', color: 'lime').tap do |label|
      label.x = (Game.width - label.width) / 2
      label.y = (Game.height - label.height) / 4
    end
  end
end
