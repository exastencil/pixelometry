class Pixelometry::Font
  # Reusable Font registry
  @@fonts = {}

  attr_reader :name, :path, :size

  def self.register(font)
    @@fonts[font.name.to_sym] = font
  end

  def self.get(name)
    if @@fonts.has_key? name
      @@fonts[name]
    else
      raise Pixelometry::Error, "Font #{name} not found! Have you loaded it?"
    end
  end

  def initialize(name, opts)
    @name = name
    @path = opts[:path]
    @size = opts[:size] || 12
    @glyphs = opts[:glyphs]

    self.class.register self
  end

  def glyph(encoding)
    unless @glyphs[encoding]
      raise Pixelometry::Error, "Missing glyph for encoding #{encoding} (#{encoding.chr}) in font `#{name}`"
    end

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
    raise Pixelometry::Error, "Could not load sprite for font #{name} at #{opts[:path]}"
  end
end
