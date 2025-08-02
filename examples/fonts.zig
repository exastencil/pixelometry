const std = @import("std");
const pixelometry = @import("pixelometry");

var my_font: ?pixelometry.Font = null;
var allocator: std.mem.Allocator = undefined;

fn init() void {
    // Initialize font - this example assumes you have a font image at "assets/font.png"
    // You would need to create this image with your bitmap font
    allocator = std.heap.page_allocator;

    // Example: Load a font with 16x16 character grid, each character is 8x16 pixels
    my_font = pixelometry.createASCIIFont(allocator, "assets/font.png", // Path to your bitmap font image
        16, // 16 characters per row
        8, // Each character is 8 pixels wide
        16, // Each character is 16 pixels tall
        0, // Grid starts at x=0
        0 // Grid starts at y=0
    ) catch |err| {
        std.log.err("Failed to load font: {}", .{err});
        return;
    };

    // Alternative: Load font and add characters manually
    // my_font = pixelometry.Font.init(allocator, "assets/font.png") catch |err| {
    //     std.log.err("Failed to load font image: {}", .{err});
    //     return;
    // };
    //
    // // Add individual characters manually
    // if (my_font) |*font| {
    //     font.addChar('A', 0, 0, 8, 16) catch {}; // 'A' at position (0,0), size 8x16
    //     font.addChar('B', 8, 0, 8, 16) catch {}; // 'B' at position (8,0), size 8x16
    //     // ... add more characters as needed
    // }

    std.log.info("Font initialized successfully!");
}

fn frame() void {
    // Example of how you would measure text
    if (my_font) |*font| {
        const text = "Hello, World!";
        const text_width = font.measureText(text);
        const text_height = font.getHeight();

        std.log.debug("Text '{}' dimensions: {}x{}", .{ text, text_width, text_height });

        // Example of getting UV coordinates for rendering a character
        if (font.getCharUV('H')) |uv| {
            std.log.debug("Character 'H' UV coords: [{d}, {d}, {d}, {d}]", .{ uv[0], uv[1], uv[2], uv[3] });
        }

        // Example of getting character info
        if (font.getChar('H')) |char_info| {
            std.log.debug("Character 'H' info: pos=({}, {}), size={}x{}", .{ char_info.x, char_info.y, char_info.width, char_info.height });
        }
    }

    // Here you would typically render text using the font texture and UV coordinates
    // This would involve creating textured quads with the font texture applied
}

fn cleanup() void {
    if (my_font) |*font| {
        font.deinit();
        my_font = null;
    }
}

pub fn main() void {
    const config = pixelometry.AppConfig{
        .title = "Font Example",
        .width = 800,
        .height = 600,
    };

    const callbacks = pixelometry.AppCallbacks{
        .init_fn = init,
        .frame_fn = frame,
        .cleanup_fn = cleanup,
    };

    pixelometry.runApp(config, callbacks);
}
