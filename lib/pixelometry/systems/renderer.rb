# # Renderer class
#
# A Pixelometry `Renderer` is a `System` that inspects the properties of
# `renderable?` entities in the `Scene` it is attached to and sets their Ruby2D
# `Sprite` accordingly. This varies in what type of scene you are using.
#
class Renderer < System
  def self.process(entity)
    # Guard against rendering everything
    return unless entity.renderable?
  end
end

Dir[File.join(__dir__, 'renderers', '*.rb')].each { |file| require file }
