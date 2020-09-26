# # The `anchored` attribute
#
# Specifies that the entity's position, relates to a point on the entity.
# This is most often used to render sprites in a way that makes sense.
#
define_attribute :anchored do |options|
  options ||= {}

  # The x-coordinate
  property :anchor_x, default: options[:x] || 0

  # The y-coordinate
  property :anchor_y, default: options[:y] || 0

  # The z-coordinate
  property :anchor_z, default: options[:z] || 0
end
