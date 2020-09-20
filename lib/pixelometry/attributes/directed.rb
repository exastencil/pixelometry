# # The `directed` attribute
#
# Specifies that the entity has direction, composed of an `x`, `y` and `z`
# component. Components not in use can safely be ignored
#
define_attribute :directed do |options|
  options ||= {}

  # The x-coordinate direction
  property :x_direction, default: options[:x] || 0

  # The y-coordinate direction
  property :y_direction, default: options[:y] || 0

  # The z-coordinate direction
  property :z_direction, default: options[:z] || 0
end
