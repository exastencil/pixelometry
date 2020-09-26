class WorldSpaceRenderer < Renderer
  # Default render position is top left corner
  def self.position_to_screen_space(entity)
    x = entity.x
    y = entity.y
    z = entity.z

    if entity.anchored?
      x -= entity.anchor_x
      y -= entity.anchor_y
      z -= entity.anchor_z
    end

    [
      Game.width / 2 + x + y,
      Game.height / 2 + x / 2 - y / 2 - z
    ]
  end


  # Z-ordering: lower things are rendered first
  # Depth ordering: further things in X/Y are rendered first
  def self.render_order(entity, other)
    [entity.z, entity.x - entity.y] <=> [other.z, other.x - other.y]
  end

  def self.depth_order(entity)
    if entity.anchored?
      ((entity.z + entity.anchor_z) * 100) + (entity.x + entity.anchor_x) - (entity.y + entity.anchor_y)
    else
      entity.z * 100 + entity.x - entity.y
    end
  end
end
