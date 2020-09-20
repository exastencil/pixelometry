class ScreenSpaceRenderer < Renderer
  def self.process(entity)
    # Skip entities that aren't renderable
    return unless entity.renderable?

    # Assign a Sprite
    entity.sprite ||= if entity.animated?
                        Sprite.new(
                          entity.asset_path,
                          x: entity.x, y: entity.y,
                          width: entity.frame_width,
                          height: entity.frame_height,
                          clip_width: entity.frame_width,
                          clip_height: entity.frame_height
                        )
                      else
                        Sprite.new(
                          entity.asset_path,
                          x: entity.x, y: entity.y,
                          width: entity.sprite_width,
                          height: entity.sprite_height
                        )
                      end

    # For animated entities set the current frame
    if entity.animated?
      # Frame configuration for the current animation
      frames = entity.animations[entity.animation]
      # Determine which frame we are in
      frame = if frames.size > 1 && entity.animation_started
                current_time = (Time.now.to_f * 1000).to_i
                elapsed_time = current_time - entity.animation_started
                current_frame = 0
                frames.each do |frame|
                  if elapsed_time >= frame[:duration]
                    elapsed_time -= frame[:duration]
                    current_frame += 1
                  else
                    break
                  end
                end
                if current_frame >= frames.size
                  total_time = frames.sum { |f| f[:duration] }
                  # TODO: Animation is done, loop if necessary
                  entity.animation_started += total_time
                  frames.first
                else
                  frames[current_frame]
                end
              else
                frames.first
              end
      # Set the clipping in the Sprite to the selected frame
      entity.sprite.clip_x = frame[:x]
      entity.sprite.clip_y = frame[:y]
    end

    # For entities that change direction we flip the sprite
    if entity.directed?
      entity.sprite.flip_sprite(entity.x_direction.negative? ? :horizontal : nil)
    end
  end
end