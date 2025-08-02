const std = @import("std");
const pxl = @import("pixelometry");
const ui = pxl.UI;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var clay_state: ?pxl.ClayState = null;

fn init() void {
    const allocator = gpa.allocator();

    // Initialize the renderer
    pxl.Renderer.initialize(800.0, 600.0, allocator) catch |err| {
        std.log.err("Failed to initialize Clay renderer: {}", .{err});
        return;
    };

    // Initialize Clay
    clay_state = pxl.ClayState.init(allocator, 800.0, 600.0) catch |err| {
        std.log.err("Failed to initialize Clay: {}", .{err});
        return;
    };

    std.log.info("UI example initialized!", .{});
}

fn frame() void {
    if (clay_state == null) return;

    var clay_st = &clay_state.?;

    // Begin Clay layout
    clay_st.beginLayout();

    // Create a simple UI layout
    createLayout();

    // End layout and get render commands
    const render_commands = clay_st.endLayout();

    // Render the commands
    pxl.Renderer.renderUI(render_commands);
}

fn createLayout() void {
    // Root container
    ui.UI()(.{
        .id = .ID("RootContainer"),
        .layout = .{
            .direction = .top_to_bottom,
            .sizing = .grow,
            .padding = .all(20),
            .child_gap = 16,
        },
        .background_color = .{ 0, 0, 0, 0 },
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

fn cleanup() void {
    if (clay_state) |*state| {
        state.deinit();
    }

    // Deinitialize the renderer
    pxl.Renderer.deinitialize();

    _ = gpa.deinit();
    std.log.info("UI example cleaned up!", .{});
}

fn handleEvent(event: *const @import("sokol").app.Event) void {
    _ = event;
    // Handle events here if needed
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
        .event_fn = handleEvent,
    });
}
