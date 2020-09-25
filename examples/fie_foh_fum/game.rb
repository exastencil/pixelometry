require 'pixelometry'

require "#{__dir__}/../assets/terminus"

define_entity :title do
  attribute :renderable, asset_path: "#{__dir__}/assets/text.png", width: 128, height: 16
end

define_entity :bars do
  attribute :renderable, asset_path: "#{__dir__}/assets/bars.png", width: 128, height: 128
end

define_attribute :clickable do
  # Whether this slot is still responsive
  property :enabled, default: true

  # Hover
  on :mouse_move do
    # Ignore assigned slots
    if enabled
      if Window.mouse_x >= x && Window.mouse_x <= x + frame_width && Window.mouse_y >= y && Window.mouse_y <= y + frame_height
        self.opacity = 0.3
      else
        self.opacity = 0.0
      end
    end
  end

  # Click handler
  on :mouse_down do
    if enabled && Window.mouse_x >= x && Window.mouse_x <= x + frame_width && Window.mouse_y >= y && Window.mouse_y <= y + frame_height
      self.occupant = :player
      self.enabled = false
      self.opacity = 1.0
      emit :player_move
    end
  end
end

define_entity :slot do
  # Stores `nil`, `:player` or `:opponent`
  property :occupant

  # Where this slot fits on the board
  property :index

  attribute :renderable, asset_path: "#{__dir__}/assets/marks.png", width: 64, height: 32, opacity: 0.0
  attribute :animated, width: 32, height: 32, animations: {
    player: 0,
    opponent: 1
  }

  attribute :clickable
end

define_game title: 'Fie, foh, fum', width: 128, height: 24 + 128 + 24 do
  create_scene renderer: ScreenSpaceRenderer do
    # Title
    create_entity :title, y: 4
    # Board
    create_entity :bars, y: 24
    # Instructions
    click = create_entity :label, text: 'Click a space to move', x: 7, y: 30 + 128, font: :terminus, color: '#d9a066'
    won   = create_entity :label, text: 'You have won!',         x: 7, y: 30 + 128, font: :terminus, color: '#d9a066', visible: false
    lost  = create_entity :label, text: 'You have lost!',        x: 7, y: 30 + 128, font: :terminus, color: '#d9a066', visible: false
    tied  = create_entity :label, text: 'You have tied!',        x: 7, y: 30 + 128, font: :terminus, color: '#d9a066', visible: false

    # Slots
    slots = [
      [0, 0], [1, 0], [2, 0], # 0 1 2
      [0, 1], [1, 1], [2, 1], # 3 4 5
      [0, 2], [1, 2], [2, 2]  # 6 7 8
    ].each_with_index.map do |col_and_row, index|
      x, y = col_and_row
      create_entity :slot, x: 8 + (128 / 3) * x, y: 24 + 8 + (128 / 3) * y, index: index
    end

    # Opponent AI
    create_entity do
      on :player_move do
        available = slots.select { |s| s.occupant.nil? }.sample
        if available
          available.occupant = :opponent
          available.animation = :opponent
          available.enabled = false
          available.opacity = 1.0
        end
      end
    end

    # Check for win condition
    each_frame do
      if click.visible
        # No one has won
        rows      = [[0, 1, 2], [3, 4, 5], [6, 7, 8]]
        columns   = [[0, 3, 6], [1, 4, 7], [2, 5, 8]]
        diagonals = [[0, 4, 8], [2, 4, 6]]

        (rows + columns + diagonals).any? do |slot_indices|
          if slot_indices.all? { |i| slots[i].occupant == :player }
            click.visible = false
            won.visible = true
          end
          if slot_indices.all? { |i| slots[i].occupant == :opponent }
            click.visible = false
            lost.visible = true
          end
        end

        unless slots.any? { |slot| slot.occupant.nil? }
          if click.visible
            click.visible = false
            tied.visible = true
          end
        end
      else
        # Someone has won
        slots.each { |s| s.enabled = false }
      end
    end
  end
end
