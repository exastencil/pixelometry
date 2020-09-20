# # The `positioned` attribute
#
# Specifies that the entity has a position, composed of an `x`, `y` and `z`
# coordinate. This is most often used to render sprites at that position.
#
define_attribute :positioned do |options|
  options ||= {}

  # The x-coordinate
  property :x, default: options[:x] || 0

  # The y-coordinate
  property :y, default: options[:y] || 0

  # The z-coordinate
  property :z, default: options[:z] || 0
end
