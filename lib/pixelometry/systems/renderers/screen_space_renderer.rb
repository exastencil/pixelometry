require 'chunky_png'

class ScreenSpaceRenderer < Renderer
  def self.process(entity)
    # Skip entities that aren't renderable
    return unless entity.renderable? || entity.typographical?

    if entity.renderable?
      # Free sprite if no longer visible
      unless entity.visible
        entity.sprite&.remove
        return
      end

      # Assign a Sprite
      entity.sprite ||= if entity.animated?
                          Sprite.new(
                            entity.asset_path,
                            x: entity.x, y: entity.y,
                            width: entity.frame_width,
                            height: entity.frame_height,
                            clip_width: entity.frame_width,
                            clip_height: entity.frame_height,
                            opacity: entity.opacity
                          )
                        else
                          Sprite.new(
                            entity.asset_path,
                            x: entity.x, y: entity.y,
                            width: entity.sprite_width,
                            height: entity.sprite_height,
                            opacity: entity.opacity
                          )
                        end

      # Update opacity
      entity.sprite.opacity = entity.opacity

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
                    # Animation is done, loop if necessary or stop on last frame
                    if entity.animation_repeats == true
                      entity.animation_started += total_time
                      frames.first
                    elsif entity.animation_repeats > 1 # Already ran once, so repeat only if needed twice
                      entity.animation_repeats -= 1
                      entity.animation_started += total_time
                      frames.first
                    else
                      entity.animation_started = nil
                      frames.last
                    end
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

    if entity.typographical?
      # Free Sprites or Text if no longer visible
      unless entity.visible
        Array[entity.text_object].flatten.compact.each(&:remove)
        return
      end

      if entity.font.is_a? Symbol
        # Pixelometry::Font
        unless entity.text_object
          font = Pixelometry::Font.get entity.font
          x_offset = 0
          entity.text_object = entity.text.each_codepoint.map do |encoding|
            glyph = font.glyph encoding
            x_offset += glyph[:width]
            Sprite.new(
              font.path,
              {
                x: entity.x + x_offset - glyph[:width],
                y: entity.y,
                width: glyph[:width],
                clip_width: glyph[:width],
                clip_x: glyph[:clip_x],
                color: entity.color,
                opacity: entity.opacity
              }
            )
          end.flatten
        end
      else
        # Ruby2D::Text
        if entity.text_object
          entity.text_object.text = entity.text
          entity.text_object.x = entity.x
          entity.text_object.y = entity.y
          entity.text_object.rotate = entity.rotation
          entity.text_object.size = entity.font_size
        else
          entity.text_object = Text.new(
            entity.text,
            x: entity.x,
            y: entity.y,
            z: entity.z,
            color: entity.color,
            rotate: entity.rotation,
            opacity: entity.opacity,
            size: entity.font_size
          )
        end
      end
    end
  end
end
