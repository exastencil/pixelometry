# 4. Ruby2D Sprite with Animation

Now we're starting to get somewhere useful. We'll use a Ruby2D native `Sprite`
and set up some animations for it. Then we'll use the keys to change the
direction and animation.

Here is the first part where Ruby2D is starting to get in the way. Let's look
at what could be improved here.

### Animation Data

We can specify frames as a `Range` such as we're doing here (`1..3`) or as an
`Array` which is a little more flexible. However, the array method requires you
to "cut out" each frame with it's x, y, width and height.

In our case the `idle` animation is a single frame which is no problem, but the
`walk` animation is a 3-frame animation that is meant to go `[1, 2, 3, 2]`. But
to get that cycle we would have to use the following:

```ruby
Sprite.new(
  ...,
  animations: {
    walk: [
      { x:  0, y: 0, width: 32, height: 48, time: 150 },
      { x: 32, y: 0, width: 32, height: 48, time: 150 },
      { x: 64, y: 0, width: 32, height: 48, time: 150 },
      { x: 32, y: 0, width: 32, height: 48, time: 150 },
    ]
  }
)
```

### State Management

In my initial implementation of this example when you held `right` key and then
let go, you would notice the sprite turn to face left again. This was because
we have to indicate whether to flip the animation when we play it. In other
words during the `:key_up` event, where we don't know what the previous
animation was. This is the original implementation:

```ruby
on :key_up do |event|
  sprites.each do |sprite|
    sprite.play animation: :idle, loop: true
  end
end
```

In this case we can reasonably infer that the key that was released is the
direction they were walking. Therefore this is a reasonable approach:

```ruby
on :key_up do |event|
  sprites.each do |sprite|
    sprite.play animation: :idle, loop: true, flip: event.key == 'right' ? :horizontal : false
  end
end
```

However, imagine there is an attack button which would attack left or right
depending on the current facing and afterwards switch to an idle animation
in the same direction. Now we can't look at the key pressed since it will be
the attack key. For this we need to store state that can be looked up each
time a directional animation is played.

So an improvement here would be to decouple the animation structure from the
direction and instead have a sort of state machine that is checked inherently.

## Running

Run the following from the `pixelometry` gem's root folder:

```sh
bundle exec ruby examples/004_sprite/game.rb
```

## Credits

- [Isometric Human Sprites](https://bunsisanmon.itch.io/isometric-human-sprites) by [BunsiSanmon](https://bunsisanmon.itch.io/)
