## 7. Label Entities

Instead of using `Ruby2D:Text` for labels (which are not `Entity`s) we can
use the `:label` entity template. It just exposes the properties needed to
manipulate the a `Ruby2D:Text` in a way that conforms to `renderable`.

## Running

Run the following from the `pixelometry` gem's root folder:

```sh
bundle exec ruby examples/007_labels/game.rb
```
