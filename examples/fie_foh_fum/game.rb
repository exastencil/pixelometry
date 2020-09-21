require 'pixelometry'

define_entity :text do
  attribute :renderable, asset_path: "#{__dir__}/assets/text.png", width: 128, height: 180
  attribute :animated, width: 128, height: 16, animations: {
    title: 0,
    click: 1,
    win: 2,
    lose: 3,
    tie: 4
  }
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
    create_entity :text, y: 4
    # Board
    create_entity :bars, y: 24
    # Instructions
    message = create_entity :text, y: 24 + 128 + 4, animation: :click

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
      if message.animation == :click
        # No one has won
        rows      = [[0, 1, 2], [3, 4, 5], [6, 7, 8]]
        columns   = [[0, 3, 6], [1, 4, 7], [2, 5, 8]]
        diagonals = [[0, 4, 8], [2, 4, 6]]

        (rows + columns + diagonals).any? do |slot_indices|
          message.play :win if slot_indices.all? { |i| slots[i].occupant == :player }
          message.play :lose if slot_indices.all? { |i| slots[i].occupant == :opponent }
        end

        unless slots.any? { |slot| slot.occupant.nil? }
          message.play :tie if message.animation == :click
        end
      else
        # Someone has won
        slots.each { |s| s.enabled = false }
      end
    end
  end
end
