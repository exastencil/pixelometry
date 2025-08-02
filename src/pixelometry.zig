const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const slog = sokol.log;
const clay = @import("zclay");
const renderer = @import("renderer.zig");
const font = @import("font.zig");

// Re-export renderer and Color for convenience
pub const Renderer = renderer;
pub const Color = renderer.Color;

// Re-export Font for convenience
pub const Font = font.Font;
pub const CharInfo = font.CharInfo;
pub const createASCIIFont = font.createASCIIFont;
pub const createDummyASCIIFont = font.createDummyASCIIFont;
pub const setFont = renderer.setFont;

// Re-export Clay as UI for convenience
pub const UI = clay;

/// Configuration for a Pixelometry application
///
/// The width and height specified here is in intended pixel coordinates
pub const AppConfig = struct {
    title: [:0]const u8,
    width: i32,
    height: i32,
};

/// Callbacks for a Pixelometry application
pub const AppCallbacks = struct {
    init_fn: ?*const fn () void = null,
    frame_fn: ?*const fn () void = null,
    cleanup_fn: ?*const fn () void = null,
    event_fn: ?*const fn (*const sapp.Event) void = null,
};

/// Pixelometry application state
pub const App = struct {
    config: AppConfig,
    pass_action: sg.PassAction = .{},

    const Self = @This();

    /// Initialize a new Pixelometry app with the given configuration
    pub fn init(config: AppConfig) Self {
        return Self{
            .config = config,
            .pass_action = .{
                .colors = [_]sg.ColorAttachmentAction{.{
                    .load_action = .CLEAR,
                    .clear_value = .{ .r = 0.0, .g = 0.0, .b = 0.0, .a = 1.0 },
                }} ** 4,
            },
        };
    }

    /// Run the Pixelometry application
    pub fn run(self: *Self) void {
        // Store reference to self in a global for callback access
        current_app = self;

        sapp.run(.{
            .init_cb = appInit,
            .frame_cb = appFrame,
            .cleanup_cb = appCleanup,
            .event_cb = appEvent,
            .width = self.config.width,
            .height = self.config.height,
            .window_title = @ptrCast(self.config.title),
            .icon = .{ .sokol_default = true },
            .logger = .{ .func = slog.func },
        });
    }

    /// Override this method to implement custom frame rendering
    pub fn onFrame(self: *Self) void {
        _ = self;
        // Default implementation just clears the screen
    }

    /// Override this method to implement custom cleanup
    pub fn onCleanup(self: *Self) void {
        _ = self;
        // Default implementation does nothing
    }
};

// Global reference to current app and callbacks (needed for C callbacks)
var current_app: ?*App = null;
var current_callbacks: AppCallbacks = .{};
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

/// Simple function to run a Pixelometry app with callbacks
pub fn runApp(config: AppConfig, callbacks: AppCallbacks) void {
    var app = App.init(config);
    current_callbacks = callbacks;
    app.run();
}

// Sokol callback functions
export fn appInit() void {
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });

    if (current_app) |app| {
        std.log.info("Pixelometry app '{s}' initialized ({}x{})!", .{ app.config.title, app.config.width, app.config.height });

        // Initialize the renderer after Sokol is set up
        const allocator = gpa.allocator();

        renderer.init(allocator, @floatFromInt(app.config.width), @floatFromInt(app.config.height)) catch |err| {
            std.log.err("Failed to initialize renderer: {}", .{err});
            return;
        };

        // Call init callback if requested
        if (current_callbacks.init_fn) |init_fn| {
            init_fn();
        }
    }
}

export fn appFrame() void {
    if (current_app) |app| {
        // Begin rendering
        sg.beginPass(.{
            .action = app.pass_action,
            .swapchain = sglue.swapchain(),
        });

        // Call function callback if available, otherwise call method
        renderer.renderFrame(current_callbacks.frame_fn);

        sg.endPass();
        sg.commit();
    }
}

export fn appCleanup() void {
    // Determine which cleanup function to use
    current_app.?.onCleanup();
    renderer.deinit();
    sg.shutdown();
    _ = gpa.deinit();
}

export fn appEvent(e: [*c]const sapp.Event) void {
    // Check for window resize events
    if (e.*.type == sapp.EventType.RESIZED) {
        renderer.updateScreenSize(@floatFromInt(e.*.framebuffer_width), @floatFromInt(e.*.framebuffer_height));
    }

    // Call function callback if available, otherwise call method
    if (current_callbacks.event_fn) |event_fn| {
        event_fn(@ptrCast(e));
    }
}
