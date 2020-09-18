require 'thor/group'
require 'active_support/inflector'

module Pixelometry
  module Generators
    class Project < Thor::Group
      include Thor::Actions

      def self.source_root
        File.dirname(__FILE__) + '/templates'
      end

      argument :app_name, type: :string

      def create_project
        template 'game.rb.erb', "#{app_name}/game.rb"
      end
    end
  end
end
