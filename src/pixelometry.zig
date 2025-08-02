const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const slog = sokol.log;
const clay = @import("zclay");
const renderer = @import("renderer.zig");

// Re-export renderer, Color, and ClayState for convenience
pub const Renderer = renderer;
pub const Color = renderer.Color;
pub const ClayState = renderer.ClayState;

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

    /// Override this method to implement custom initialization
    pub fn onInit(self: *Self) void {
        _ = self;
        // Default implementation does nothing
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

    /// Override this method to handle events
    pub fn onEvent(self: *Self, event: *const sapp.Event) void {
        _ = self;
        _ = event;
        // Default implementation does nothing
    }
};

// Global reference to current app and callbacks (needed for C callbacks)
var current_app: ?*App = null;
var current_callbacks: AppCallbacks = .{};

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

        // Call function callback if available, otherwise call method
        if (current_callbacks.init_fn) |init_fn| {
            init_fn();
        } else {
            app.onInit();
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
        if (current_callbacks.frame_fn) |frame_fn| {
            frame_fn();
        } else {
            app.onFrame();
        }

        sg.endPass();
        sg.commit();
    }
}

export fn appCleanup() void {
    if (current_app) |app| {
        // Call function callback if available, otherwise call method
        if (current_callbacks.cleanup_fn) |cleanup_fn| {
            cleanup_fn();
        } else {
            app.onCleanup();
        }
    }
    sg.shutdown();
}

export fn appEvent(e: [*c]const sapp.Event) void {
    if (current_app) |app| {
        // Call function callback if available, otherwise call method
        if (current_callbacks.event_fn) |event_fn| {
            event_fn(@ptrCast(e));
        } else {
            app.onEvent(@ptrCast(e));
        }
    }
}
