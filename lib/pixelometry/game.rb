require 'singleton'

require 'pixelometry/scene'

# Game Singleton Class
#
# The `Game` class encompasses some setup state and interfaces with Ruby2D on
# your behalf so you don't have to hook into things like input callbacks.
class Game
  # There should only ever be one `Game`
  include Singleton

  # This is the width we will use in all of our calculations
  @@target_width = 640

  # This is the height we will use in all of our calculations
  @@target_height = 480

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
  Game.class_exec(&block)

  Window.update do
    Game.update
  end

  Window.on(:key) { |e| Game.trigger e }

  Window.show
end
