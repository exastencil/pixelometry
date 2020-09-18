# Pixelometry

Pixelometry is a gem that helps you build isometric pixel art games on top of
[Ruby2D](https://ruby2d.com). It aims to add utility classes and a DSL to it,
that not only removes the tedium of building a game with only code, but also
applies the structure and optimizations that make sense for such a game.

A good way to think of it is as a [Gamebox](https://gamebox.io) for
[Ruby2D](https://ruby2d.com) for isometric pixel art games. The approach taken
will be to start as a gem (which will require a typical Ruby runtime) and to
later add support for [mruby](https://mruby.org/) and native builds.

## Installation

If using Bundler add this line to your application's Gemfile:

```ruby
gem 'pixelometry'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install pixelometry

## Usage

In most cases you would want to start a project with Pixelometry:

```sh
pxl new <YOUR_APP_NAME_HERE>
```

This will generate a folder with a basic starting point for you. See the
[examples](https://github.com/exastencil/pixelometry/examples) for examples
of how to get started.

If you already have a Ruby2D app, you can simply `require 'pixelometry'`
right after Ruby2D to get access to the DSL and classes.

```ruby
require 'ruby2d'
require 'pixelometry' # just add this
```

## Development

This gem is currently in development and has not yet been released. Examples
will be created for all the features, so that is a good indication of progress.
The following is needed before it will be released:

- Entity Component System (sort of)
- Scene Management
- State Serialization
- Common predefined systems
  - Isometric Depth-sorted Rendering
  - Input System
  - Animation State
  - Simple Isometric Physics

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/exastencil/pixelometry. This project is intended to be a
safe, welcoming space for collaboration, and contributors are expected to
adhere to the
[code of conduct](https://github.com/exastencil/pixelometry/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Pixelometry project's codebases, issue trackers,
chat rooms and mailing lists is expected to follow the
[code of conduct](https://github.com/exastencil/pixelometry/blob/master/CODE_OF_CONDUCT.md).
