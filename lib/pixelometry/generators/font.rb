require 'thor/group'
require 'active_support/inflector'
require 'bdf'
require 'chunky_png'

module Pixelometry
  module Generators
    class Font < Thor::Group
      include Thor::Actions

      def self.source_root
        File.dirname(__FILE__) + '/templates'
      end

      argument :font_path, type: :string, required: true

      def create_font_file
        bdf = BDF::Font.from_file font_path

        # Determine properties of the font
        @font_family = bdf.properties['FAMILY_NAME']
        @font_weight = bdf.properties['WEIGHT_NAME']
        @font_width  = bdf.properties['SETWIDTH_NAME']
        @font_slant  = bdf.properties['SLANT'] || 'R'
        @font_size   = bdf.properties['PIXEL_SIZE']
        @font_ascent = bdf.properties['FONT_ASCENT']
        @font_descent = bdf.properties['FONT_DESCENT']

        # Prepare to generate the sprite sheet
        chars = bdf.instance_variable_get('@chars')
        glyph_count = chars.size
        texture_width = chars.sum { |_c, attrs| attrs[:dwidth][:x] }
        texture_height = @font_size

        # Generate the sprite sheet using ChunkyPNG
        png = ChunkyPNG::Image.new texture_width, texture_height, ChunkyPNG::Color::TRANSPARENT
        cursor = 0
        @glyph_markers = {}

        chars.each do |_name, char|
          @glyph_markers[char[:encoding]] = [cursor, char[:dwidth][:x]]
          char[:bitmap]&.each_with_index do |line_string, row|
            line_string.to_i(16).to_s(2).rjust(line_string.size * 4, '0').each_char.with_index do |bitstring, column|
              next unless bitstring === '1'

              png[
                cursor + column + char[:bbx][:off_x],
                row - char[:bbx][:h] + @font_ascent - char[:bbx][:off_y]
              ] = ChunkyPNG::Color 'white'
            end
          end
          cursor += char[:dwidth][:x]
        end

        @sprite_path = "assets/#{@font_family.underscore}.png"
        File.open(@sprite_path, 'wb') { |io| png.write(io) }
        template 'font.rb.erb', "fonts/#{@font_family.underscore}.rb"
      end
    end
  end
end
