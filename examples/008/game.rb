# Load Ruby2D and Pixelometry
require 'pixelometry'

# Load a bitmap font
require "#{__dir__}/../assets/terminus"

# Load entity templates
define_entity :marker do
  attribute :renderable, asset_path: "#{__dir__}/../assets/marker.png", width: 3, height: 3
  attribute :anchored
end

define_entity :box do
  attribute :positioned
  attribute :renderable, width: 48, height: 42, asset_path: "#{__dir__}/../assets/box.png"
end

define_entity :character do
  attribute :positioned
  attribute :anchored, x: 16
  attribute :renderable, width: 96, height: 192, asset_path: "#{__dir__}/../assets/man.png"
  attribute :animated, default: :idle, width: 32, height: 48, duration: 150, animations: {
    idle: 1
  }
end

define_game title: 'World Space Rendering' do
  create_scene renderer: WorldSpaceRenderer do
    create_entity :box, x: -20, y: -100
    create_entity :box, x:  40, y: -140
    create_entity :box, x:  40, y: -80

    label = create_entity :label, y: -150, z: 30, text: '← → ↑ ↓', color: 'lime', font: :terminus do
      attribute :anchored, x: 8, y: 8
    end
    create_entity :character, y: -150 do
      on :key_held do |event|
        case event.key
        when 'left'   then self.x -= 1
        when 'right'  then self.x += 1
        when 'up'     then self.y += 1
        when 'down'   then self.y -= 1
        end

        label.x = x
        label.y = y
      end
    end
  end

  create_scene renderer: WorldSpaceRenderer do
    create_entity :label, text: 'World Origin', x: 0, y: 0, font: :terminus, color: 'green'
    create_entity :marker, anchor_x: 1

    create_entity :label, text: 'Positive X', x: 100, font: :terminus, color: 'green'
    create_entity :marker, x: 100, anchor_x: 1

    create_entity :label, text: 'Positive Y', y: 100, font: :terminus, color: 'green'
    create_entity :marker, y: 100, anchor_x: 1

    create_entity :label, text: 'Positive Z', z: 100, font: :terminus, color: 'green'
    create_entity :marker, z: 100, anchor_x: 1
  end

  create_scene renderer: ScreenSpaceRenderer do
    create_entity :label, text: 'Screen Origin', x: 0, y: 0, font: :terminus, color: 'red'
    create_entity :marker, anchor_x: 1, anchor_y: 1

    create_entity :label, text: 'Positive X', x: 200, font: :terminus, color: 'red'
    create_entity :marker, x: 200, anchor_x: 1, anchor_y: 1

    create_entity :label, text: 'Positive Y', y: 50, font: :terminus, color: 'red'
    create_entity :marker, y: 50, anchor_x: 1, anchor_y: 1
  end
end
