# # The `renderable` attribute
#
# Specifies that the entity can be rendered in the scene with a sprite.
# At the very least it needs to be `positioned`. It adds `sprite` and
# `asset_path` properties. It can be augmented with additional attributes
# like `directed` and `animated`.
#
define_attribute :renderable do |options|
  options ||= {}
  unless options[:width] && options[:height]
    raise Pixelometry::Error.new 'Missing dimensions for `renderable`. Please provide `:width` and `:height` to `attribute :renderable`.'
  end

  # It needs a position to be rendered
  attribute :positioned unless positioned?

  # This property contains the `Ruby2D::Sprite` that will be updated on each frame
  property :sprite

  property :sprite_width,   default: options[:width]
  property :sprite_height,  default: options[:height]

  # The `asset_path` property is used to pass the sprite(sheet) to be loaded
  property :asset_path, default: options[:asset_path]

  # The sprite opacity (from 0.0 -> transparent to 1.0 -> opaque)
  property :opacity, default: options[:opacity] || 1.0
end
