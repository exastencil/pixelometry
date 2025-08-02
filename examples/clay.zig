const std = @import("std");
const pxl = @import("pixelometry");
const ui = pxl.UI;

// Global font instance
var terminus_font: ?pxl.Font = null;

/// Create the Terminus font with proper character mapping
/// This uses the exact glyph mapping from the terminus font spritesheet
fn createTerminusFont(allocator: std.mem.Allocator, image_path: []const u8) !pxl.Font {
    var font = try pxl.Font.init(allocator, image_path);

    // Add characters based on the exact terminus font mapping
    // All characters have y=0, height=12, width=6, and specific x positions
    const mappings = [_]struct { codepoint: u21, x: u32 }{
        .{ .codepoint = 0, .x = 0 },
        .{ .codepoint = 32, .x = 6 }, // space
        .{ .codepoint = 33, .x = 12 }, // !
        .{ .codepoint = 34, .x = 18 }, // "
        .{ .codepoint = 35, .x = 24 }, // #
        .{ .codepoint = 36, .x = 30 }, // $
        .{ .codepoint = 37, .x = 36 }, // %
        .{ .codepoint = 38, .x = 42 }, // &
        .{ .codepoint = 39, .x = 48 }, // '
        .{ .codepoint = 40, .x = 54 }, // (
        .{ .codepoint = 41, .x = 60 }, // )
        .{ .codepoint = 42, .x = 66 }, // *
        .{ .codepoint = 43, .x = 72 }, // +
        .{ .codepoint = 44, .x = 78 }, // ,
        .{ .codepoint = 45, .x = 84 }, // -
        .{ .codepoint = 46, .x = 90 }, // .
        .{ .codepoint = 47, .x = 96 }, // /
        .{ .codepoint = 48, .x = 102 }, // 0
        .{ .codepoint = 49, .x = 108 }, // 1
        .{ .codepoint = 50, .x = 114 }, // 2
        .{ .codepoint = 51, .x = 120 }, // 3
        .{ .codepoint = 52, .x = 126 }, // 4
        .{ .codepoint = 53, .x = 132 }, // 5
        .{ .codepoint = 54, .x = 138 }, // 6
        .{ .codepoint = 55, .x = 144 }, // 7
        .{ .codepoint = 56, .x = 150 }, // 8
        .{ .codepoint = 57, .x = 156 }, // 9
        .{ .codepoint = 58, .x = 162 }, // :
        .{ .codepoint = 59, .x = 168 }, // ;
        .{ .codepoint = 60, .x = 174 }, // <
        .{ .codepoint = 61, .x = 180 }, // =
        .{ .codepoint = 62, .x = 186 }, // >
        .{ .codepoint = 63, .x = 192 }, // ?
        .{ .codepoint = 64, .x = 198 }, // @
        .{ .codepoint = 65, .x = 204 }, // A
        .{ .codepoint = 66, .x = 210 }, // B
        .{ .codepoint = 67, .x = 216 }, // C
        .{ .codepoint = 68, .x = 222 }, // D
        .{ .codepoint = 69, .x = 228 }, // E
        .{ .codepoint = 70, .x = 234 }, // F
        .{ .codepoint = 71, .x = 240 }, // G
        .{ .codepoint = 72, .x = 246 }, // H
        .{ .codepoint = 73, .x = 252 }, // I
        .{ .codepoint = 74, .x = 258 }, // J
        .{ .codepoint = 75, .x = 264 }, // K
        .{ .codepoint = 76, .x = 270 }, // L
        .{ .codepoint = 77, .x = 276 }, // M
        .{ .codepoint = 78, .x = 282 }, // N
        .{ .codepoint = 79, .x = 288 }, // O
        .{ .codepoint = 80, .x = 294 }, // P
        .{ .codepoint = 81, .x = 300 }, // Q
        .{ .codepoint = 82, .x = 306 }, // R
        .{ .codepoint = 83, .x = 312 }, // S
        .{ .codepoint = 84, .x = 318 }, // T
        .{ .codepoint = 85, .x = 324 }, // U
        .{ .codepoint = 86, .x = 330 }, // V
        .{ .codepoint = 87, .x = 336 }, // W
        .{ .codepoint = 88, .x = 342 }, // X
        .{ .codepoint = 89, .x = 348 }, // Y
        .{ .codepoint = 90, .x = 354 }, // Z
        .{ .codepoint = 91, .x = 360 }, // [
        .{ .codepoint = 92, .x = 366 }, // \
        .{ .codepoint = 93, .x = 372 }, // ]
        .{ .codepoint = 94, .x = 378 }, // ^
        .{ .codepoint = 95, .x = 384 }, // _
        .{ .codepoint = 96, .x = 390 }, // `
        .{ .codepoint = 97, .x = 396 }, // a
        .{ .codepoint = 98, .x = 402 }, // b
        .{ .codepoint = 99, .x = 408 }, // c
        .{ .codepoint = 100, .x = 414 }, // d
        .{ .codepoint = 101, .x = 420 }, // e
        .{ .codepoint = 102, .x = 426 }, // f
        .{ .codepoint = 103, .x = 432 }, // g
        .{ .codepoint = 104, .x = 438 }, // h
        .{ .codepoint = 105, .x = 444 }, // i
        .{ .codepoint = 106, .x = 450 }, // j
        .{ .codepoint = 107, .x = 456 }, // k
        .{ .codepoint = 108, .x = 462 }, // l
        .{ .codepoint = 109, .x = 468 }, // m
        .{ .codepoint = 110, .x = 474 }, // n
        .{ .codepoint = 111, .x = 480 }, // o
        .{ .codepoint = 112, .x = 486 }, // p
        .{ .codepoint = 113, .x = 492 }, // q
        .{ .codepoint = 114, .x = 498 }, // r
        .{ .codepoint = 115, .x = 504 }, // s
        .{ .codepoint = 116, .x = 510 }, // t
        .{ .codepoint = 117, .x = 516 }, // u
        .{ .codepoint = 118, .x = 522 }, // v
        .{ .codepoint = 119, .x = 528 }, // w
        .{ .codepoint = 120, .x = 534 }, // x
        .{ .codepoint = 121, .x = 540 }, // y
        .{ .codepoint = 122, .x = 546 }, // z
        .{ .codepoint = 123, .x = 552 }, // {
        .{ .codepoint = 124, .x = 558 }, // |
        .{ .codepoint = 125, .x = 564 }, // }
        .{ .codepoint = 126, .x = 570 }, // ~
    };

    // Add all the basic ASCII characters with proper positioning
    // All terminus characters are 6 pixels wide and 12 pixels tall
    for (mappings) |mapping| {
        try font.addChar(mapping.codepoint, mapping.x, 0, 6, 12);
    }

    return font;
}

fn init() void {
    // Load the actual terminus font
    const allocator = std.heap.page_allocator;

    // Load terminus font from PNG with proper character mapping
    if (createTerminusFont(allocator, "examples/fonts/terminus.png")) |font| {
        terminus_font = font;
    } else |err| {
        std.log.warn("Failed to load terminus font ({}), using dummy font", .{err});

        // Fall back to dummy font
        terminus_font = pxl.createDummyASCIIFont(allocator, 8, 12) catch |fallback_err| {
            std.log.err("Failed to create dummy font: {}", .{fallback_err});
            return;
        };
    }

    if (terminus_font) |*font| {
        std.log.info("Font loaded successfully!", .{});

        // Set the font for Clay text measurement
        pxl.setFont(font);

        // Test measurement
        const test_text = "Hello, World!";
        const width = font.measureText(test_text);
        std.log.info("Text '{s}' width: {d} pixels", .{ test_text, width });
    }
}

fn cleanup() void {
    if (terminus_font) |*font| {
        font.deinit();
        terminus_font = null;
    }
}

pub fn main() void {
    pxl.runApp(.{
        .title = "Pixelometry UI Example",
        .width = 800,
        .height = 600,
    }, .{
        .init_fn = init,
        .frame_fn = frame,
        .cleanup_fn = cleanup,
    });
}

fn frame() void {
    // Root container
    ui.UI()(.{
        .id = .ID("RootContainer"),
        .layout = .{
            .direction = .top_to_bottom,
            .sizing = .grow,
            .padding = .all(20),
            .child_gap = 16,
        },
        .background_color = .{ 255, 255, 255, 255 },
    })({
        // Header
        ui.UI()(.{
            .id = .ID("Header"),
            .layout = .{
                .direction = .left_to_right,
                .sizing = .{ .w = .grow, .h = .fixed(60) },
                .padding = .all(16),
                .child_alignment = .{ .x = .center, .y = .center },
            },
            .background_color = .{ 100, 149, 237, 255 },
        })({
            ui.text("Pixelometry + Clay UI", .{
                .font_size = 24,
                .color = .{ 0, 0, 0, 255 },
            });
        });

        // Content area
        ui.UI()(.{
            .id = .ID("Content"),
            .layout = .{
                .direction = .left_to_right,
                .sizing = .grow,
                .child_gap = 16,
            },
        })({
            // Sidebar
            ui.UI()(.{
                .id = .ID("Sidebar"),
                .layout = .{
                    .direction = .top_to_bottom,
                    .sizing = .{ .w = .fixed(200), .h = .grow },
                    .padding = .all(16),
                    .child_gap = 8,
                },
                .background_color = .{ 200, 200, 200, 255 },
            })({
                ui.text("Sidebar", .{
                    .font_size = 18,
                    .color = .{ 0, 0, 0, 255 },
                });

                // Sidebar items
                for (0..5) |i| {
                    sidebarItem(@intCast(i));
                }
            });

            // Main content
            ui.UI()(.{
                .id = .ID("MainContent"),
                .layout = .{
                    .direction = .top_to_bottom,
                    .sizing = .grow,
                    .padding = .all(16),
                    .child_gap = 12,
                },
                .background_color = .{ 200, 200, 200, 255 },
            })({
                ui.text("Main Content Area", .{
                    .font_size = 20,
                    .color = .{ 0, 0, 0, 255 },
                });

                ui.text("This is a demonstration of Clay UI integration with Pixelometry.", .{
                    .font_size = 14,
                    .color = pxl.Color.rgba(64, 64, 64, 255).toClayColor(),
                });

                ui.text("Clay provides responsive layout capabilities that will be used for UI anchoring.", .{
                    .font_size = 14,
                    .color = pxl.Color.rgba(64, 64, 64, 255).toClayColor(),
                });
            });
        });
    });
}

fn sidebarItem(index: u32) void {
    ui.UI()(.{
        .id = .IDI("SidebarItem", index),
        .layout = .{
            .sizing = .{ .w = .grow, .h = .fixed(40) },
            .padding = .all(8),
            .child_alignment = .{ .x = .left, .y = .center },
        },
        .background_color = .{ 255, 165, 0, 255 },
    })({
        var buffer: [32]u8 = undefined;
        const text = std.fmt.bufPrint(&buffer, "Item {}", .{index + 1}) catch "Item";
        ui.text(text, .{
            .font_size = 14,
            .color = .{ 255, 255, 255, 255 },
        });
    });
}
