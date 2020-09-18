require 'pixelometry'

# Since we will have two, let's define the template and reuse it
define_entity :character do
  # Screen position to render the sprite
  property :x, default: 0
  property :y, default: Window.height / 2

  # Which direction the sprite is facing
  property :direction, default: :left

  # Which animation should be playing
  property :animation_state, default: :idle

  # A path to the sprite so we can specify the sprite sheet
  property :asset_path

  # The Ruby2D `Sprite` used to render to the screen
  property :sprite

  # Behavior to change direction and start walking on key press
  behavior :walking, on: :key_down do |event|
    self.direction = :left if event.key == 'left'
    self.direction = :right if event.key == 'right'
    self.animation_state = :walking
  end

  # Behavior to stop walking and idle on key release
  behavior :idle, on: :key_up do |event|
    self.animation_state = :idle if %w[left right].include? event.key
  end
end

# Set up the structure of our game
define_game title: 'Pixelometry Sprite Example' do
  # The game will have one scene
  create_scene do
    # Display instructions (same as previous implementation)
    Text.new('Press Left or Right to walk', color: 'lime').tap do |label|
      label.x = (Window.width - label.width) / 2
      label.y = (Window.height - label.height) / 4
    end

    create_entity :character, x: Window.width / 2 - 64, asset_path: "#{__dir__}/assets/man.png"
    create_entity :character, x: Window.width / 2 + 32, asset_path: "#{__dir__}/assets/woman.png"

    # Our own custom implementation of a render system
    # This block gets called once each frame for each entity
    create_system :renderer do |character|
      # Create a sprite once only (Sprites are 96 x 192)
      character.sprite ||= Sprite.new(
        character.asset_path,
        x: character.x, y: character.y,
        width: 96 / 3,                                  # sprite width
        height: 192 / 4,                                # sprite height
        clip_width: 96 / 3,                             # Frame width
        clip_height: 192 / 4                            # Frame height
      )

      # Render the frame based on the `animation_state`
      # Since we're only using the top row, instead of frames we can simply
      # vary the x-offset that we want to render
      case character.animation_state
      when :idle then character.sprite.clip_x = 32
      when :walking
        # The x-offsets `[0, 32, 64, 32]` means left, middle, right, middle
        # frames. In the array indexing `Window.frames / 9` means every 9
        # frames the index changes (roughly 150ms) to match the previous
        # example. The modulo simply wraps the sequence so it repeats.
        character.sprite.clip_x = [0, 32, 64, 32][(Window.frames / 9) % 4]
      end

      # To handle the direction change we just flip the sprite
      character.sprite.flip_sprite(character.direction == :right ? :horizontal : nil)
    end
  end
end
