require 'thor'

require 'pixelometry/generators/entity'
require 'pixelometry/generators/font'

module Pixelometry
  class CLI < Thor
    desc 'new APP_NAME', 'Generate a new blank project at current location in folder `APP_NAME`'
    def new(app_name = 'example')
      Pixelometry::Generators::Project.start [app_name]
    end

    desc 'generate RESOURCE NAME', 'Generates a resource from a template'
    def generate(type, class_name)
      case type
      when 'entity'
        Pixelometry::Generators::Entity.start [class_name]
      else
        raise "Unknown resource type #{type} (supported types: entity)"
      end
    end

    desc 'font PATH', 'Generates a font sprite from a BDF file and registers it'
    def font(path)
      Pixelometry::Generators::Font.start [path]
    end
  end
end
