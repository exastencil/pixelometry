class Pixelometry::Font
  # Reusable Font registry
  @@fonts = {}

  attr_reader :name, :path, :size

  def self.register(font)
    @@fonts[font.name.to_sym] = font
  end

  def self.get(name)
    @@fonts[name]
  end

  def initialize(name, opts)
    @name = name
    @path = opts[:path]
    @size = opts[:size] || 12
    @glyphs = opts[:glyphs]

    self.class.register self
  end

  def glyph(encoding)
    {
      clip_x: @glyphs[encoding][0],
      width: @glyphs[encoding][1],
      height: @size
    }
  end
end

def define_font(name, opts = {})
  if File.exist? opts[:path]
    Pixelometry::Font.new name.to_sym, opts
  else
    raise Pixelometry::Error.new "Could not load sprite for font #{name} at #{path}"
  end
end
