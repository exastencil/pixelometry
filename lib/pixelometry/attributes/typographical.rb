# Typographical attribute
#
# Indicates that this entity is used to render text.
#
define_attribute :typographical do
  # The text to display
  property :text

  # Acts as a short-circuit for rendering
  property :visible, default: true

  # Property to store the `Ruby2D::Text` used to render the text
  property :text_object

  # A `Ruby2D::Font` or `Pixelometry::Font` to use
  property :font, default: Font.default

  # The font size in points
  property :font_size, default: 20

  # The angle of rotation
  property :rotation, default: 0

  # The opacity to render the text at
  property :opacity, default: 1.0

  # The color for the text
  property :color, default: 'white'
end
