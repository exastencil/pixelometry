## 5. Pixelometry Sprite with Animation

OK, let's introduce the Pixelometry concepts gradually. Let's show how we could
recreate the previous example with Pixelometry added into the mix.

This is the first time we even need the library, but we will already need quite
a few concepts. Here is the approach we will take:

> To achieve this example we need a Scene with two Entities. They will each
> need Properties for their position on screen, the direction they are facing
> and what animation state they are in. We then make use of an event system
> to listen to Events when a key is pressed or released and add a Behavior to
> the entities to change the animation state and direction. We will use a
> render System in to render the correct frame of the animation on every frame.

Since that probably didn't make much sense, we'll explain the concepts used in
that description. Read through it and come back to the description above and it
should make more sense.

First, we'll use Pixelometry primitives to structure our app as above. Then
we'll show how you can do the same with built-in Pixelometry structures.

### Scenes

Everything that Pixelometry does, it does in a `Scene`. Think of a scene as all
the things that need to interact with each other and be rendered together. You
can layer scenes over each other or call Ruby2D methods before or after scenes
to create backgrounds or overlays outside of scenes.

### Entities

An `Entity` is basically anything the game engine keeps track of. It allows us
to treat everything more or less the same by giving it a common interface
(like the `Object` class in Ruby). Essentially, everything in a `Scene` is an
`Entity`.

### Properties

A property allows us to store state on an `Entity` that it or other entities
might care about.

### Behavior

A `Behavior` is code attached to an `Entity`. It can be declared once-off for
an entity or defined and reused by many entities. There are two main uses for
behaviors: continuously running code and reacting to events.

### Events

All external interaction on entities come from an `Event`. Events can be
dispatched by an `Entity` or a `System`.

### Systems

A `System` is simply a way to track entities and dispatch `Event`s between
them.

## Running

Run the following from the `pixelometry` gem's root folder:

```sh
bundle exec ruby examples/005/game.rb
```

## Credits

- [Isometric Human Sprites](https://bunsisanmon.itch.io/isometric-human-sprites) by [BunsiSanmon](https://bunsisanmon.itch.io/)
