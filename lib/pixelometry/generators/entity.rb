require 'thor/group'
require 'active_support/inflector'

module Pixelometry
  module Generators
    class Entity < Thor::Group
      include Thor::Actions

      def self.source_root
        File.dirname(__FILE__) + '/templates'
      end

      argument :template_name, type: :string

      def empty_entity
        template 'entity.rb.erb', "entities/#{template_name}.rb"
      end
    end
  end
end
