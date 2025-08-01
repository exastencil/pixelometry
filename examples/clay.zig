const std = @import("std");
const pxl = @import("pixelometry");
const clay = pxl.Clay;
const clay_renderer = @import("../src/clay_sokol_renderer.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var clay_state: ?pxl.ClayState = null;
var renderer: ?pxl.Renderer = null;

fn init() void {
    const allocator = gpa.allocator();

    // Initialize the Sokol Clay renderer
    clay_renderer.initialize(800.0, 600.0, allocator) catch |err| {
        std.log.err("Failed to initialize Clay renderer: {}", .{err});
        return;
    };

    // Initialize Clay
    clay_state = pxl.ClayState.init(allocator, 800.0, 600.0) catch |err| {
        std.log.err("Failed to initialize Clay: {}", .{err});
        return;
    };

    // Initialize renderer
    renderer = pxl.Renderer.init(800.0, 600.0);

    std.log.info("Clay example initialized!", .{});
}

fn frame() void {
    if (clay_state == null or renderer == null) return;

    var clay_st = &clay_state.?;
    var rend = &renderer.?;

    // Begin Clay layout
    clay_st.beginLayout();

    // Create a simple UI layout
    createLayout();

    // End layout and get render commands
    const render_commands = clay_st.endLayout();

    // Render the commands
    rend.renderClayCommands(render_commands);
}

fn createLayout() void {
    const white: clay.Color = .{ 255, 255, 255, 255 };
    const light_grey: clay.Color = .{ 200, 200, 200, 255 };
    const blue: clay.Color = .{ 100, 149, 237, 255 };

    // Root container
    clay.UI()(.{
        .id = .ID("RootContainer"),
        .layout = .{
            .direction = .top_to_bottom,
            .sizing = .grow,
            .padding = .all(20),
            .child_gap = 16,
        },
        .background_color = white,
    })({
        // Header
        clay.UI()(.{
            .id = .ID("Header"),
            .layout = .{
                .direction = .left_to_right,
                .sizing = .{ .w = .grow, .h = .fixed(60) },
                .padding = .all(16),
                .child_alignment = .{ .x = .center, .y = .center },
            },
            .background_color = blue,
        })({
            clay.text("Pixelometry + Clay UI", .{
                .font_size = 24,
                .color = white,
            });
        });

        // Content area
        clay.UI()(.{
            .id = .ID("Content"),
            .layout = .{
                .direction = .left_to_right,
                .sizing = .grow,
                .child_gap = 16,
            },
        })({
            // Sidebar
            clay.UI()(.{
                .id = .ID("Sidebar"),
                .layout = .{
                    .direction = .top_to_bottom,
                    .sizing = .{ .w = .fixed(200), .h = .grow },
                    .padding = .all(16),
                    .child_gap = 8,
                },
                .background_color = light_grey,
            })({
                clay.text("Sidebar", .{
                    .font_size = 18,
                    .color = .{ 0, 0, 0, 255 },
                });

                // Sidebar items
                for (0..5) |i| {
                    sidebarItem(@intCast(i));
                }
            });

            // Main content
            clay.UI()(.{
                .id = .ID("MainContent"),
                .layout = .{
                    .direction = .top_to_bottom,
                    .sizing = .grow,
                    .padding = .all(16),
                    .child_gap = 12,
                },
                .background_color = light_grey,
            })({
                clay.text("Main Content Area", .{
                    .font_size = 20,
                    .color = .{ 0, 0, 0, 255 },
                });

                clay.text("This is a demonstration of Clay UI integration with Pixelometry.", .{
                    .font_size = 14,
                    .color = .{ 64, 64, 64, 255 },
                });

                clay.text("Clay provides responsive layout capabilities that will be used for UI anchoring.", .{
                    .font_size = 14,
                    .color = .{ 64, 64, 64, 255 },
                });
            });
        });
    });
}

fn sidebarItem(index: u32) void {
    const orange: clay.Color = .{ 255, 165, 0, 255 };
    const white: clay.Color = .{ 255, 255, 255, 255 };

    clay.UI()(.{
        .id = .IDI("SidebarItem", index),
        .layout = .{
            .sizing = .{ .w = .grow, .h = .fixed(40) },
            .padding = .all(8),
            .child_alignment = .{ .x = .left, .y = .center },
        },
        .background_color = orange,
    })({
        var buffer: [32]u8 = undefined;
        const text = std.fmt.bufPrint(&buffer, "Item {}", .{index + 1}) catch "Item";
        clay.text(text, .{
            .font_size = 14,
            .color = white,
        });
    });
}

fn cleanup() void {
    if (clay_state) |*state| {
        state.deinit();
    }
    
    // Deinitialize the clay renderer
    clay_renderer.deinitialize();
    
    _ = gpa.deinit();
    std.log.info("Clay example cleaned up!", .{});
}

fn handleEvent(event: *const @import("sokol").app.Event) void {
    _ = event;
    // Handle events here if needed
}

pub fn main() void {
    pxl.runApp(.{
        .title = "Pixelometry Clay Example",
        .width = 800,
        .height = 600,
    }, .{
        .init_fn = init,
        .frame_fn = frame,
        .cleanup_fn = cleanup,
        .event_fn = handleEvent,
    });
}
