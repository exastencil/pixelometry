# # The `positioned` attribute
#
# Specifies that the entity has a position, composed of an `x`, `y` and `z`
# coordinate. This is most often used to render sprites at that position.
#
define_attribute :positioned do |options|
  options ||= {}
  defaults = options[:default] || {}

  # The x-coordinate
  property :x, default: defaults[:x] || 0

  # The y-coordinate
  property :y, default: defaults[:y] || 0

  # The z-coordinate
  property :z, default: defaults[:z] || 0
end
