# Pixelometry

A lightweight game engine designed for creating isometric pixel-buffer games with
precise pixel-perfect rendering, 3D physics calculations, and responsive UI
anchoring.

## Overview

Pixelometry specializes in creating a very specific kind of game: **isometric
pixel-buffer games** with lightweight UI that are predominantly
controller-operated. The engine generates scenes with models in 3D space and
performs physics calculations in 3D, but renders objects and UI using 2D pixel
sprites to ensure perfect pixel alignment.

### Key Features

- **Pixel-Perfect Rendering**: All sprites and UI elements are rendered without
  scaling, maintaining consistent pixel sizes
- **3D Physics, 2D Rendering**: Full 3D scene calculations with 2D sprite-based
  visual output
- **Responsive Canvas**: Dynamic resolution scaling that adapts to available
  screen space
- **Responsive UI System**: Clay UI integration provides flexible, responsive
  layouts that adapt to screen size
- **Immediate Mode UI**: Clean, composable UI components with automatic layout
  management
- **Target Resolution Design**: Design assets for a specific resolution with
  intelligent upscaling

## How It Works

### Resolution System

1. **Target Resolution**: You specify a target resolution for your game design
2. **Dynamic Scaling**: The engine allocates an appropriate multiple of the
   target resolution within available screen space
3. **Aspect Ratio Adaptation**: The target resolution is centered, with width
   or height extended (never more than double)
4. **Responsive Canvas**: UI elements move appropriately as the screen resizes
   based on their anchor points

### Rendering Pipeline

1. **3D Scene Calculation**: Physics and scene logic operate in full 3D space
2. **Clay UI Layout**: Responsive immediate-mode UI with automatic layout
   calculations
3. **GPU Rendering**: Hardware-accelerated rendering with batched draw calls
   for optimal performance

## Technical Details

- **Language**: [Zig](https://ziglang.org/)
- **Graphics Backend**: [Sokol](https://github.com/floooh/sokol) (cross-platform
  graphics library)
- **Platforms**: Native (Windows, macOS, Linux) and Web (WebAssembly)
- **Version**: 0.1.0

## Dependencies

- **sokol-zig**: Cross-platform graphics, audio, and input library
- **zclay**: Responsive immediate-mode UI library for layout management
- **Zig**: Version compatible with current sokol-zig bindings

## Building

### Prerequisites

- [Zig](https://ziglang.org/download/) (latest stable release recommended)

### Native Build

```bash
# Build the library
zig build

# Run the basic example
zig build run

# Run specific examples
zig build run-basic
zig build run-clay
```

### Web Build

```bash
# Build for web (requires Emscripten)
zig build -Dtarget=wasm32-emscripten

# Run web version
zig build run -Dtarget=wasm32-emscripten
```

## Quick Start

### Basic Example

```zig
const pxl = @import("pixelometry");

pub fn main() void {
    pxl.runApp(.{
        .title = "My Pixelometry Game",
        .width = 800,
        .height = 600,
    }, .{
        .init_fn = init,
        .frame_fn = frame,
        .cleanup_fn = cleanup,
        .event_fn = handleEvent,
    });
}

fn init() void {
    // Initialize your game state
}

fn frame() void {
    // Render your game frame
}

fn cleanup() void {
    // Clean up resources
}

fn handleEvent(event: *const sapp.Event) void {
    // Handle input events
}
```

### Object-Oriented Approach

```zig
const pxl = @import("pixelometry");

const MyGame = struct {
    app: pxl.App,

    pub fn init() MyGame {
        return MyGame{
            .app = pxl.App.init(.{
                .title = "My Game",
                .width = 1024,
                .height = 768,
            }),
        };
    }

    pub fn run(self: *MyGame) void {
        self.app.run();
    }

    // Override App methods
    pub fn onInit(self: *MyGame) void {
        // Custom initialization
    }

    pub fn onFrame(self: *MyGame) void {
        // Custom frame rendering
    }
};

pub fn main() void {
    var game = MyGame.init();
    game.run();
}
```

## Project Structure

```
pixelometry/
├── src/
│   ├── pixelometry.zig      # Main engine framework and app lifecycle
│   ├── renderer.zig         # Sokol-based renderer with Clay UI integration
│   └── shader.zig           # Auto-generated shader bindings
├── shaders/
│   └── pixel.glsl           # GLSL shader source for 2D rendering
├── examples/
│   ├── basic.zig            # Basic usage example
│   └── clay.zig             # Clay UI example with responsive layout
├── build.zig                # Build configuration with shader compilation
├── build.zig.zon            # Package manifest with dependencies
└── README.md                # This file
```

## Development Status

🚧 **Early Development** - Pixelometry is currently in early development. The
core application framework is implemented, but many of the advanced features
described in the overview (3D-to-2D rendering pipeline, UI anchoring system,
multi-buffer composition) are planned for future releases.

### Current Features

- ✅ Basic application framework
- ✅ Sokol graphics integration
- ✅ Clay UI integration with responsive layouts
- ✅ Hardware-accelerated rendering with batching
- ✅ Cross-platform support (native + web)
- ✅ Example applications

### Planned Features

- 🔄 3D scene management with 2D sprite rendering
- 🔄 Sprite batching and texture atlas support
- 🔄 Responsive resolution scaling
- 🔄 Controller input handling
- 🔄 Asset management system

## Contributing

This project is in active development. Contributions, feedback, and suggestions
are welcome!

## License

[Add your license information here]

---

**Note**: This README reflects the current state and future vision of
Pixelometry. Some features described in the overview are planned for
implementation and may not yet be available in the current codebase.
