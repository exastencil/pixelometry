## 8. World Space Rendering

When dealing with 3D objects we need a way to render them onto the screen. This
is typically done with a 3D engine (where everything is actually 3D) or a
tilemap system, where everything is actually 2D.

Pixelometry was created to bridge this divide. While all rendering is 2D, world
space is 3D. We can use the `WorldSpaceRenderer` instead of the
`ScreenSpaceRenderer` with a scene where objects are placed correctly.

Unlike using tilemaps, you can place entities as you like in 3D space using
pixel units. In most cases you'll want them tiled or connected for
environments, but they can be disconnected too, like players enemies or
particles.

The coordinate system has its origin in the center of the screen (for
convenience and in case you want to support varying screen resolutions). The
axes run as you would hold your left hand pointing forward with your thumb,
index finger and middle finger at right angles. Then:

- your middle finger is the positive X axis, (towards bottom right of the screen)
- your index finger is the positive Y axis, (towards top right of the screen) and
- your thumb is the positive Z axis (towards the top middle of the screen).

Rendering occurs from back to front, but since we aren't using tiles there can
be overlap and "back" depends on a combination of axes, not just `z` as before.

Technically, this is dimetric projection, not isometric projection. Dimetric
projection makes more sense since moving along the x- and y-axes is more even,
which makes the world-space to screen-space calculation much simpler.

All collisions and other physics calculations are also done in this pixel unit.

## Running

Run the following from the `pixelometry` gem's root folder:

```sh
bundle exec ruby examples/008/game.rb
```
