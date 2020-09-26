class ScreenSpaceRenderer < Renderer
  # Screen Space plots `x` and `y` uniformly
  def self.position_to_screen_space(entity)
    if entity.anchored?
      [entity.x - entity.anchor_x, entity.y - entity.anchor_y]
    else
      [entity.x, entity.y]
    end
  end

  # Screen Space uses z-index for render order
  def self.render_order(entity, other)
    entity.z <=> other.z
  end
end
