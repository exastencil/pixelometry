## 6. Pixelometry Entities using Builtins

Most of what we did in the previous example was a lot more verbose because we
only used the primitives that Pixelometry provides. You would likely prefer
writing the code in example 4. However, making use of these structures is
particularly useful for reuse. Since so much of what we did is common on so
many entities in so many games, we can bake the behavior in and compose it as
needed.

So let's use `attribute`s to recreate the almost the same `entities` as before.
Attributes are like groupings of properties that work together to provide some
functionality, like specifying where the entity is (`positioned`) or how to
render an entity using a sprite (`renderable`). Attributes have some added
benefits like implicitly defining other attributes and adding helper methods to
check if an attribute is present, e.g. `attribute :awesome` defines `awesome?`
on `Entity` which returns `true` for entities with that attribute.

One change we will make is redo how we specify animations so it can be a little
more flexible. Now we can define an animation as a single frame (idle) or an
Array of frame numbers (not just a range). We also add a more complex example
with uneven timings.

The man uses the `[0, 1, 2, 1]` even cycle while the woman uses an uneven cycle
that spends more time in the arm swing frame, making for a more natural walk
animation without adding more frames.

## Running

Run the following from the `pixelometry` gem's root folder:

```sh
bundle exec ruby examples/006/game.rb
```

## Credits

- [Isometric Human Sprites](https://bunsisanmon.itch.io/isometric-human-sprites) by [BunsiSanmon](https://bunsisanmon.itch.io/)
