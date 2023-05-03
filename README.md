# DRTiled Renderer

A [DragonRuby](https://dragonruby.org/toolkit/game) rendering library for the
[Tiled Map Editor](https://www.mapeditor.org/).

## Installation

This library depends on [wildfiler](https://github.com/wildfiler)'s
[DRTiled](https://github.com/wildfiler/drtiled) library. Copy the `lib/`
directories from that repo as well as this one into the `mygame/` directory of
your DragonRuby project and you're good to go.

## Usage

At the top of your `main.rb`:

```rb
require 'lib/tiled/tiled.rb'
require 'lib/tiled_renderer/tiled_renderer.rb'
```

Load your map (see the [DRTiled](https://github.com/wildfiler/drtiled) README
for more usage information):

```rb
@map = Tiled::Map.new('path/to/map.tmx').tap(&:load)
```

Create a new `Renderer`, passing in `args` and the map you want to display:

```rb
@renderer = Tiled::Renderer.new(args, @map)
```

And now draw the map to the screen!

```rb
@renderer.render_map # Render the entire map
@renderer.render_layer(:background) # Render a single layer
```

To change the map:

```rb
@renderer.map = Tiled::Map.new('path/to/level2.tmx').tap(&:load)
```

## Camera

The camera is the coordinate (measured in pixels) on the map that is drawn to
the lower-left pixel of the screen. So, if the camera is at `[0, 0]` and you
begin to move to the right such that the camera begins to follow you by e.g. 32
pixels, the camera will now be at `[32, 0]`.

### Controlling the camera

There are a couple of ways to move the camera. One is to call `Camera#move`:

```rb
@camera.move(x: 5, y: -5) # Move camera 5 pixels down and 5 pixels to the right
@camera.move(x: -5)       # Move camera to the left
@camera.move(y: 10)       # Move camera up quickly
```

You can also track an object around the screen. You can pass in any hash
primitive with `x`, `y`, `w`, and `h` parameters such as a sprite or a solid,
or an array of 4 numbers:

```rb
# Assuming a sprite named `@player` is being controlled...
@camera.track(@player)
```

Easing functions to smoothly follow the player are coming soon.

### Tracking external primitives

To render primitives that aren't part of the map so that they are affected by
the camera's movement:

```rb
@renderer.render_primitive(@player)
```

In this way, you can think about your primitive's `x` and `y` properties
as its coordinates on the **map**, not on your screen; the `Renderer` will
calculate the screen coordinates for you.

### Deadzone

The camera has a "deadzone" around the center where the player can move freely
without affecting the camera's position. They can be set with
`Camera#set_deadzone`. The defaults are:

```rb
@renderer.camera.set_deadzone(up: 0, down: 128, right: 128, left: 128)
```

You may pass in individual directions, or all 4.

<img src="https://raw.githubusercontent.com/vinnydiehl/drtiled-renderer/main/doc/images/camera_origin_properties.png"
     align="right" width="191" height="420" />
     
### Camera Origin

It may be the case that you wish the camera to start at some point out in the
middle of a large level. `[0, 0]` is always the lower-left corner of the map,
however, you can change the starting point of the camera from Tiled by setting
custom properties on the map. To get to the map properties, navigate to `Map ->
Map Properties...` in the toolbar, then right-click on "Custom Properties" in
the properties window, click "Add Property", and a window will pop up. Select
"int" in the drop-down, name the property either "Camera Origin X" or "Camera
Origin Y", click "OK", and then enter the desired value. You can set one or
both; they will default to 0 if unset.

### Parallax

Set the "X" and "Y" values underneath "Parallax Factor" in the **layer** properties
(brought about simply by clicking on the layer in the layers window) to change
the speed at which that layer moves relative to the other layers. Use a
value lower than 1 for farther away layers such as backgrounds to make them
scroll slower than the rest of the scene, and values higher than 1 for
foreground layers that should move by more quickly. When done well, this gives
the illusion of a 3D environment.

<br clear="right /">

## Sample Apps

There are sample apps included. They are:

 * **Platformer** - A super simple demo that lets you move a sprite back and
                    forth along the ground. It demonstrates camera movement,
                    external sprite tracking, and parallax.
 * **RPG** - A sample [Pipoya](https://pipoya.itch.io/pipoya-rpg-tileset-32x32)
             map. Demonstrates camera panning and animated tiles.

To use the sample apps, put the root of this repo into an empty `mygame`
directory in a freshly unzipped DragonRuby project. You will need to install
the [DRTiled](https://github.com/wildfiler/drtiled) library; clone the repo and
copy his `lib/` directory into this repo. Don't worry, you won't accidentally
commit it; it's in the `.gitignore`.

Run `./dragonruby` and the app will run. Use the left and right arrow keys to
switch between the sample apps, and WASD or a controller to move.

## Contributing

Feel free to open an issue or send a pull request if you have any ideas.

If you wish to contribute a sample app, just put it in its own file, build the
app in a class with a constructor that takes `args`, and a `tick` method.
Add the `require` to
`[main.rb](https://github.com/vinnydiehl/drtiled-renderer/blob/main/app/main.rb)`,
and add the name of your class (case-sensitive) to the `SAMPLE_APPS` array
just below the `require`s.

### Testing

I did a whole lot of plumbing and ductwork so that all you have to do is dive
in and start writing RSpec. If you use `rbenv`, this project is pinned at
Ruby 2.7.8, as it is more similar to the runtime that DragonRuby runs on than
Ruby 3. If you want to run the tests on Ruby 3, they will work, but they will
let more things slide through that wouldn't work on DragonRuby.

You will need [Active
Support](https://github.com/rails/rails/tree/main/activesupport) installed in
order to run the test suite. Once you have, running `rspec` from the root of
this repository should do it.

If you need help testing out a feature feel free to open an issue or PR and we
can brainstorm a strategy.

### Linting

[RuboCop](https://rubocop.org/) is available. The configuration is incomplete;
if the bot suggests something stupid, maybe fix it, or just ignore it, but if
a guard is already in there don't remove it without good reason.

## License

This library is released under the MIT license. See the
[`LICENSE.md`](https://github.com/vinnydiehl/drtiled-renderer/blob/main/LICENSE.md)
file included with this code or
[the official page on OSI](http://opensource.org/licenses/MIT) for more information.
