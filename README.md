# Pixelometry

A pixel graphics library built with Zig and Sokol.

## Building and Running

```bash
# Run the basic example
zig build run

# Build for web (requires Emscripten)
zig build -Dtarget=wasm32-emscripten
```

## Usage

Pixelometry provides a simple API for creating graphics applications. You can configure the window title, size, and background color:

```zig
const pixelometry = @import("pixelometry");

pub fn main() void {
    pixelometry.runApp(.{
        .title = "My App",
        .width = 800,
        .height = 600,
    }, .{
        .init_fn = onInit,
        .frame_fn = onFrame,
        .cleanup_fn = onCleanup,
        .event_fn = onEvent,
    });
}

fn onInit() void {
    // Initialize your graphics resources
}

fn onFrame() void {
    // Render your frame
}

fn onCleanup() void {
    // Clean up resources
}

fn onEvent(event: *const @import("sokol").app.Event) void {
    // Handle input events
}
```

### Configuration Options

- `title`: Window title (string)
- `width`: Window width in pixels (i32)
- `height`: Window height in pixels (i32)
- `clear_color`: Background color (RGBA values from 0.0 to 1.0)

### Callbacks

All callbacks are optional:

- `init_fn`: Called once during initialization
- `frame_fn`: Called every frame for rendering
- `cleanup_fn`: Called once during cleanup
- `event_fn`: Called for input/window events

## Examples

See the `examples/` directory for usage examples:

- `basic.zig` - Shows all callback functions
- `custom.zig` - Shows minimal usage with custom window size

## Features

- Cross-platform rendering with Sokol
- Web compilation support
- Configurable window properties
- Simple callback-based API
- Built-in event handling

## Dependencies

- [sokol-zig](https://github.com/floooh/sokol-zig) - Cross-platform graphics library
