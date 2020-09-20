# This entity template is a wrapper for a `Ruby2D::Text`.
#
# It is provided in-library so that special accommodation can be made for it in
# `Renderer`s
define_entity :label do
  # Provides `x`, `y` and `z` properies used in rendering
  attribute :positioned

  # Provides `text`, `font`, `font_size`, `rotation`, `opacity` and `color`
  attribute :typographical
end
