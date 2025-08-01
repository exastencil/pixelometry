const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const slog = sokol.log;
const clay = @import("zclay");
const clay_renderer = @import("clay_sokol_renderer.zig");

// Re-export Clay for convenience
pub const Clay = clay;

/// Clay UI integration state
pub const ClayState = struct {
    arena: clay.Arena,
    memory: []u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, screen_width: f32, screen_height: f32) !ClayState {
        const min_memory_size: u32 = clay.minMemorySize();
        const memory = try allocator.alloc(u8, min_memory_size);
        const arena = clay.createArenaWithCapacityAndMemory(memory);

        _ = clay.initialize(arena, .{ .w = screen_width, .h = screen_height }, .{});
        clay.setMeasureTextFunction(void, {}, measureText);

        return ClayState{
            .arena = arena,
            .memory = memory,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *ClayState) void {
        self.allocator.free(self.memory);
    }

    pub fn beginLayout(self: *ClayState) void {
        _ = self;
        clay.beginLayout();
    }

    pub fn endLayout(self: *ClayState) []clay.RenderCommand {
        _ = self;
        return clay.endLayout();
    }

    pub fn setPointerState(self: *ClayState, x: f32, y: f32, mouse_down: bool) void {
        _ = self;
        clay.setPointerState(.{ .x = x, .y = y }, mouse_down);
    }
};

// Basic text measurement function for Clay
fn measureText(clay_text: []const u8, config: *clay.TextElementConfig, user_data: void) clay.Dimensions {
    _ = user_data;

    // Simple text measurement - this should be replaced with proper font measurement
    const char_width = @as(f32, @floatFromInt(config.font_size)) * 0.6; // Approximate character width
    const char_height = @as(f32, @floatFromInt(config.font_size));

    return .{
        .w = char_width * @as(f32, @floatFromInt(clay_text.len)),
        .h = char_height,
    };
}

/// Generic renderer for Pixelometry that handles both UI and scene rendering
/// Conforms to Clay's rendering API but can be extended for scene rendering
pub const Renderer = struct {
    screen_width: f32,
    screen_height: f32,

    pub fn init(screen_width: f32, screen_height: f32) Renderer {
        return Renderer{
            .screen_width = screen_width,
            .screen_height = screen_height,
        };
    }

    /// Render Clay's render commands using the Sokol renderer
    pub fn renderClayCommands(self: *Renderer, render_commands: []clay.RenderCommand) void {
        _ = self; // Not needed since we use the global clay_renderer
        clay_renderer.render(render_commands);
    }
};

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
