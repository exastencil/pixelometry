require 'singleton'

require 'pixelometry/scene'

# Game Singleton Class
#
# The `Game` class encompasses some setup state and interfaces with Ruby2D on
# your behalf so you don't have to hook into things like input callbacks.
class Game
  # There should only ever be one `Game`
  include Singleton

  @@width = 640
  @@height = 480

  def self.width
    @@width
  end

  def self.width=(w)
    @@width = w
  end

  def self.height
    @@height
  end

  def self.height=(h)
    @@height = h
  end

  @@pixel_multiple = 1

  # Find the largest integer multiple of the intended resolution that fits on
  # the screen and lock the window to that size.
  def self.calculate_scale
    @@pixel_multiple = [
      (Window.display_height - 10) / height,
      Window.display_width / width
    ].min
    Window.set(
      resizable: false, # resizing blurs pixels
      width: width * @@pixel_multiple,
      height: height * @@pixel_multiple,
      viewport_width: width,
      viewport_height: height
    )
  end

  # Ordinal storage of scenes
  @@scenes = []

  # Attribute definitions
  @@attributes = {}

  def self.create_scene(template = nil, opts = {}, &block)
    if block_given?
      # It's possible to pass options without a template
      if opts.empty? && template.is_a?(Hash)
        opts = template
        template = nil
      end
      # One off scene with optional handle
      @@scenes << Scene.new(opts[:renderer], &block)
    elsif template
      # Instantiate a Scene from a template
      @@scenes << Scene.from_template(template)
    else
      # No block or template
      raise Pixelometry::Error.new 'No template or definition passed to `create_scene`'
    end
  end

  def self.update
    @@scenes.each(&:update)
  end

  def self.trigger(event)
    kind = case event
           when Ruby2D::Window::KeyEvent
             case event.type
             when :down then :key_down
             when :up then :key_up
             else
               :unknown
             end
           when Ruby2D::Window::MouseEvent
             case event.type
             when :move then :mouse_move
             when :down then :mouse_down
             when :up then :mouse_up
             else
               :unknown
             end
           else
             :unknown
           end

    unless kind == :unknown
      @@scenes.each do |scene|
        scene.trigger kind, event
      end
    end
  end
end

def define_game(options = {}, &block)
  Window.set(
    title: options[:title] || 'Pixelometry Game'
  )

  Game.width  = options[:width]  if options[:width]
  Game.height = options[:height] if options[:height]
  Game.calculate_scale

  Game.class_exec(&block)

  Window.update do
    Game.update
  end

  Window.on(:key)   { |e| Game.trigger e }
  Window.on(:mouse) { |e| Game.trigger e }

  Window.show
end
