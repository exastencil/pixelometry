require 'chunky_png'

# # Renderer class
#
# A Pixelometry `Renderer` is a `System` that inspects the properties of
# `renderable?` entities in the `Scene` it is attached to and sets their Ruby2D
# `Sprite` accordingly. This varies in what type of scene you are using.
#
class Renderer < System
  class << self
    # Default render position is top left corner
    def position_to_screen_space(_entity)
      [0, 0]
    end

    # Default render order is to render entities created earlier first
    def render_order(entity, other)
      entity.id <=> other.id
    end

    def depth_order(entity)
      entity.z
    end

    def process(entity)
      # Skip entities that aren't renderable
      return unless entity.renderable? || entity.typographical?

      # Determine screen position based on Renderer
      screen_x, screen_y = position_to_screen_space entity

      process_renderable entity, screen_x, screen_y if entity.renderable?
      process_typographical entity, screen_x, screen_y if entity.typographical?
    end

    def process_renderable(entity, screen_x, screen_y)
      # Free sprite if no longer visible
      unless entity.visible
        entity.sprite&.remove
        return
      end

      # Assign or update Sprite
      if entity.sprite
        entity.sprite.opacity = entity.opacity
        entity.sprite.x = screen_x
        entity.sprite.y = screen_y
        entity.sprite.z = depth_order entity
      else
        entity.sprite ||= if entity.animated?
                            Sprite.new(
                              entity.asset_path,
                              x: screen_x, y: screen_y,
                              width: entity.frame_width,
                              height: entity.frame_height,
                              clip_width: entity.frame_width,
                              clip_height: entity.frame_height,
                              opacity: entity.opacity
                            )
                          else
                            Sprite.new(
                              entity.asset_path,
                              x: screen_x, y: screen_y,
                              width: entity.sprite_width,
                              height: entity.sprite_height,
                              opacity: entity.opacity
                            )
                          end
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

    def process_typographical(entity, screen_x, screen_y)
      # Free Sprites or Text if no longer visible
      unless entity.visible
        Array[entity.text_object].flatten.compact.each(&:remove)
        return
      end

      if entity.font.is_a? Symbol
        # Pixelometry::Font
        if entity.text_object
          x_offset = 0
          entity.text_object.each do |sprite|
            sprite.x = screen_x + x_offset
            sprite.y = screen_y
            sprite.z = depth_order entity
            x_offset += sprite.width
          end
        else
          font = Pixelometry::Font.get entity.font
          x_offset = 0
          entity.text_object = entity.text.each_codepoint.map do |encoding|
            glyph = font.glyph encoding
            x_offset += glyph[:width]
            Sprite.new(
              font.path,
              {
                x: screen_x + x_offset - glyph[:width],
                y: screen_y,
                z: depth_order(entity),
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
          entity.text_object.x = screen_x
          entity.text_object.y = screen_y
          entity.text_object.rotate = entity.rotation
          entity.text_object.size = entity.font_size
        else
          entity.text_object = Text.new(
            entity.text,
            x: screen_x,
            y: screen_y,
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

Dir[File.join(__dir__, 'renderers', '*.rb')].each { |file| require file }
