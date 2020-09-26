# Example Applications

Each example is a working Ruby2D / Pixelometry game. You can run them by using
`bundle exec ruby <folder>/game.rb` from this folder or
`bundle exec ruby examples/<folder>/game.rb` from the gem folder.

The sequential examples start by using Ruby2D concepts and gradually switches
over to Pixelometry concepts. Then they will show how to achieve common results
using Pixelometry, like player-controlled characters, collisions and other
interactions.

The named folders are more fleshed out sample games to give a sense of how to
implement an actual game. For more detailed documentation of each feature refer
to the documentation for explanations and capabilities.

## Smaller Examples

1. [Hello World](https://github.com/exastencil/pixelometry/tree/master/examples/001)
2. [Some Output](https://github.com/exastencil/pixelometry/tree/master/examples/002)
3. [Ruby2D Input](https://github.com/exastencil/pixelometry/tree/master/examples/003)
4. [Ruby2D Sprite with Animation](https://github.com/exastencil/pixelometry/tree/master/examples/004)
5. [Pixelometry Sprite with Animation](https://github.com/exastencil/pixelometry/tree/master/examples/005)
6. [Pixelometry Entities using Builtins](https://github.com/exastencil/pixelometry/tree/master/examples/006)
7. [Label Entities](https://github.com/exastencil/pixelometry/tree/master/examples/007)
8. [World Space Rendering](https://github.com/exastencil/pixelometry/tree/master/examples/008)

## Example Games

### [Fie, Foh, Fum](https://github.com/exastencil/pixelometry/tree/master/examples/fie_foh_fum)

This is a very simple tic tac toe game. It uses one UI scene to render some
text from a spritesheet as a title and for feedback to the user. It also has
some entities to act as "buttons" on the board for the user to click on to
make a move and store game state. It uses events passed from the buttons to
the opponent AI to trigger moves (note the bug where the opponent moves after
the victory condition due to this approach). Finally, there's a block that
executes every frame to check for a winner, sort of like a behaviour on the scene.
