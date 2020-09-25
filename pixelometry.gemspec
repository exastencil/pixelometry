require_relative 'lib/pixelometry/version'

Gem::Specification.new do |spec|
  spec.name          = 'pixelometry'
  spec.version       = Pixelometry::VERSION
  spec.author        = 'Exa Stencil'
  spec.email         = 'git@exastencil.com'

  spec.summary       = 'Extension to Ruby2D for pixel art games in isometric projection'
  spec.description   = 'Pixelometry provides utility classes, a DSL and generators for creating 2D isometric games in 3D world-space'
  spec.homepage      = 'https://github.com/exastencil/pixelometry'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new '>= 2.3.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/exastencil/pixelometry'
  spec.metadata['changelog_uri'] = 'https://github.com/exastencil/pixelometry/README.md'

  spec.add_dependency 'activesupport'
  spec.add_dependency 'chunky_png'
  spec.add_dependency 'ruby2d'
  spec.add_dependency 'ruby-bitmap-fonts'
  spec.add_dependency 'thor'

  spec.add_development_dependency 'rspec', '~> 3.8'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.glob('lib/**/*')
  spec.executables << 'pxl'
end
