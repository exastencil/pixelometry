require 'ruby2d'

require 'pixelometry/version'
require 'pixelometry/game'
require 'pixelometry/entity'
require 'pixelometry/font'
require 'pixelometry/attribute'
require 'pixelometry/system'

module Pixelometry
  class Error < StandardError; end
end

# Load the predefined attribute templates
Dir[File.join(__dir__, 'pixelometry', 'attributes', '*.rb')].each { |file| require file }

# Load the predefined entity templates
Dir[File.join(__dir__, 'pixelometry', 'entities', '*.rb')].each { |file| require file }
