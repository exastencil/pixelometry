# # The `animated` attribute
#
# Specifies that the sprite provided in `renderable` is a sprite sheet and the
# representation can be changed over time. All frames must be of equal size
# and that size must be provided in `options` as `:width` and `:height`.
#
# The `animations` property loader normalizes all the different ways of
# specifying animations. The result should be an `Array` of `Hash`es
# (`[{}, {}, ...]`) each with the following keys:
#
# - `x`: The x-position where the frame starts (left)
# - `y`: The y-position where the frame starts (top)
# - `duration`: The number of milliseconds to show the frame
# - `x_offset`: The x-offset of the anchor point for this frame (optional)
# - `y_offset`: The y-offset of the anchor point for this frame (optional)
# - `x_size`: The x-size of the bounding box for this frame (optional)
# - `y_size`: The y-size of the bounding box for this frame (optional)
# - `z_size`: The z-size of the bounding box for this frame (optional)
#
define_attribute :animated do |options|
  options ||= {}

  raise Pixelometry::Error, 'Only `renderable` entities can be animated.' unless renderable?
  unless options[:animations]
    raise Pixelometry::Error, 'No animations provided. Please specify with `:animations` on `:animated` attribute'
  end

  # These are used for calculations during rendering
  property :frame_width,  default: options[:width]
  property :frame_height, default: options[:height]

  frames_per_row = sprite_width / frame_width
  x_from_frame = ->(frame) { frame_width * (frame % frames_per_row) }
  y_from_frame = ->(frame) { frame_height * (frame / frames_per_row) }

  # The animation that is currently playing
  property :animation, default: options[:default] || options[:animations].keys.first

  # The time the current animation started
  property :animation_started

  # Should the current animation restart once finished
  property :animation_repeats, default: false

  # The animations property holds a normal set of animations
  property :animations, default: Hash[
    options[:animations].map do |name, config|
      [
        name,
        case config
        when Range
          config.to_a.map do |frame|
            {
              x: x_from_frame.call(frame),
              y: y_from_frame.call(frame),
              duration: options[:duration] || 150
            }
          end
        when Integer # Just a frame number
          [{
            x: x_from_frame.call(config),
            y: y_from_frame.call(config),
            duration: options[:duration] || 150
          }]
        when Array
          config.map do |item|
            case item
            when Integer
              {
                x: x_from_frame.call(item),
                y: y_from_frame.call(item),
                duration: options[:duration] || 150
              }
            when Hash
              frame_removed_from_item = item.delete(:frame)
              {
                x: x_from_frame.call(frame_removed_from_item),
                y: y_from_frame.call(frame_removed_from_item),
                duration: options[:duration] || 150
              }.merge(item)
            else
              # Pass through
              item
            end
          end

        else
          # Leave it as is, but it probably won't work
          config
        end
      ]
    end
  ]

  def play(animation_key, repeats = nil)
    self.animation = animation_key
    self.animation_started = (Time.now.to_f * 1000).to_i
    self.animation_repeats = repeats.nil? ? true : repeats.to_i
  end
end
