const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
const clay = @import("zclay");
const shader = @import("shader.zig");

// Matrix type for 4x4 transformation matrix
const Mat4 = [16]f32;

/// Pixelometry Color type - matches Clay's Color structure
/// Uses integer components in the range 0-255 for R, G, B, A
pub const Color = struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
    a: u8 = 255,

    /// Create a Color from RGBA values (0-255)
    pub fn rgba(r: u8, g: u8, b: u8, a: u8) Color {
        return Color{ .r = r, .g = g, .b = b, .a = a };
    }

    /// Create a Color from RGB values (0-255) with full alpha
    pub fn rgb(r: u8, g: u8, b: u8) Color {
        return Color{ .r = r, .g = g, .b = b };
    }

    /// Convert to Clay's Color format (which is [4]f32 in 0-255 range)
    pub fn toClayColor(self: Color) clay.Color {
        return .{ @floatFromInt(self.r), @floatFromInt(self.g), @floatFromInt(self.b), @floatFromInt(self.a) };
    }

    /// Create from Clay's Color format
    pub fn fromClayColor(clay_color: clay.Color) Color {
        return Color{ .r = @intFromFloat(clay_color[0]), .g = @intFromFloat(clay_color[1]), .b = @intFromFloat(clay_color[2]), .a = @intFromFloat(clay_color[3]) };
    }

    /// Convert to normalized float format (0.0-1.0) for GPU rendering
    pub fn toFloats(self: Color) [4]f32 {
        return .{
            @as(f32, @floatFromInt(self.r)) / 255.0,
            @as(f32, @floatFromInt(self.g)) / 255.0,
            @as(f32, @floatFromInt(self.b)) / 255.0,
            @as(f32, @floatFromInt(self.a)) / 255.0,
        };
    }
};

/// Simple vertex structure for 2D rendering
pub const Vertex = struct {
    pos: [2]f32,
    color: [4]f32,
};

/// Sokol-backed Renderer for Pixelometry
pub const Renderer = struct {
    // Screen dimensions
    screen_width: f32,
    screen_height: f32,
    // Target dimensions
    target_width: i32,
    target_height: i32,
    // Canvas dimensions
    canvas_width: i32,
    canvas_height: i32,
    // GPU resources
    shader_program: sg.Shader,
    vertex_buffer: sg.Buffer,
    index_buffer: sg.Buffer,
    pipeline: sg.Pipeline,
    // Vertex data staging
    vertices: [1024]Vertex, // Static buffer for vertices
    indices: [1536]u16, // Static buffer for indices (6 per rectangle: 2 triangles)
    vertex_count: u32,
    index_count: u32,
    // Current scissor state
    scissor_active: bool,
    scissor_rect: struct { x: i32, y: i32, w: i32, h: i32 },

    pub fn init(target_width: i32, target_height: i32) Renderer {
        // Create shader
        const shd = sg.makeShader(shader.pixelShaderDesc(sg.queryBackend()));

        // Create vertex buffer (dynamic for UI rendering)
        const vbuf = sg.makeBuffer(.{
            .size = @sizeOf(Vertex) * 1024,
            .usage = .{ .vertex_buffer = true, .stream_update = true },
            .label = "vertices",
        });

        // Create index buffer (dynamic for UI rendering)
        const ibuf = sg.makeBuffer(.{
            .size = @sizeOf(u16) * 1536,
            .usage = .{ .index_buffer = true, .stream_update = true },
            .label = "indices",
        });

        // Create rendering pipeline
        var layout: sg.VertexLayoutState = .{};
        layout.attrs[0] = .{ .format = .FLOAT2 }; // position
        layout.attrs[1] = .{ .format = .FLOAT4 }; // color

        const pip = sg.makePipeline(.{
            .shader = shd,
            .layout = layout,
            .index_type = .UINT16,
            .cull_mode = .NONE,
            .color_count = 1,
            .colors = .{
                .{ .blend = .{
                    .enabled = true,
                    .src_factor_rgb = .SRC_ALPHA,
                    .dst_factor_rgb = .ONE_MINUS_SRC_ALPHA,
                } },
                .{}, .{}, .{}, // Fill remaining slots
            },
            .label = "pipeline",
        });

        // Calculate dimensions
        const screen_width = @as(f32, @floatFromInt(target_width));
        const screen_height = @as(f32, @floatFromInt(target_height));

        return Renderer{
            .screen_width = screen_width,
            .screen_height = screen_height,
            .target_width = target_width,
            .target_height = target_height,
            .canvas_width = target_height,
            .canvas_height = target_height,
            .shader_program = shd,
            .vertex_buffer = vbuf,
            .index_buffer = ibuf,
            .pipeline = pip,
            .vertices = undefined,
            .indices = undefined,
            .vertex_count = 0,
            .index_count = 0,
            .scissor_active = false,
            .scissor_rect = .{ .x = 0, .y = 0, .w = 0, .h = 0 },
        };
    }

    /// Add a rectangle to the batch for rendering
    pub fn drawRect(self: *Renderer, x: f32, y: f32, width: f32, height: f32, color: Color) void {
        // Check if we have space for 4 vertices and 6 indices
        if (self.vertex_count + 4 > self.vertices.len or self.index_count + 6 > self.indices.len) {
            // Flush current batch and reset
            self.flushBatch();
        }

        // Convert screen coordinates directly to NDC to bypass matrix issues
        const x1 = (x * 2.0 / self.screen_width) - 1.0;
        const y1 = 1.0 - (y * 2.0 / self.screen_height); // Y-flip for top-left origin
        const x2 = ((x + width) * 2.0 / self.screen_width) - 1.0;
        const y2 = 1.0 - ((y + height) * 2.0 / self.screen_height);

        const vertex_start = self.vertex_count;

        // Convert color to float format for GPU
        const float_color = color.toFloats();

        // Add 4 vertices for the rectangle
        self.vertices[self.vertex_count] = Vertex{ .pos = .{ x1, y1 }, .color = float_color }; // Top-left
        self.vertex_count += 1;
        self.vertices[self.vertex_count] = Vertex{ .pos = .{ x2, y1 }, .color = float_color }; // Top-right
        self.vertex_count += 1;
        self.vertices[self.vertex_count] = Vertex{ .pos = .{ x2, y2 }, .color = float_color }; // Bottom-right
        self.vertex_count += 1;
        self.vertices[self.vertex_count] = Vertex{ .pos = .{ x1, y2 }, .color = float_color }; // Bottom-left
        self.vertex_count += 1;

        // Add 6 indices for 2 triangles
        const base_idx: u16 = @intCast(vertex_start);
        self.indices[self.index_count] = base_idx + 0;
        self.index_count += 1;
        self.indices[self.index_count] = base_idx + 1;
        self.index_count += 1;
        self.indices[self.index_count] = base_idx + 2;
        self.index_count += 1;

        self.indices[self.index_count] = base_idx + 0;
        self.index_count += 1;
        self.indices[self.index_count] = base_idx + 2;
        self.index_count += 1;
        self.indices[self.index_count] = base_idx + 3;
        self.index_count += 1;
    }

    /// Flush the current batch of vertices to GPU
    pub fn flushBatch(self: *Renderer) void {
        if (self.vertex_count == 0) return;

        // Update vertex buffer
        sg.updateBuffer(self.vertex_buffer, sg.asRange(self.vertices[0..self.vertex_count]));

        // Update index buffer
        sg.updateBuffer(self.index_buffer, sg.asRange(self.indices[0..self.index_count]));

        // Use identity matrix since we're doing coordinate conversion manually
        var proj_matrix = Mat4{
            1.0, 0.0, 0.0, 0.0,
            0.0, 1.0, 0.0, 0.0,
            0.0, 0.0, 1.0, 0.0,
            0.0, 0.0, 0.0, 1.0,
        };

        // For D3D11/HLSL, we need to transpose the matrix because it uses row-major layout
        // and the shader multiplies as mul(vector, matrix) instead of matrix * vector
        const backend = sg.queryBackend();
        if (backend == .D3D11) {
            proj_matrix = transposeMatrix(proj_matrix);
        }

        const vs_params = .{ .mvp = proj_matrix };

        // Apply pipeline and render
        sg.applyPipeline(self.pipeline);
        var bindings: sg.Bindings = .{};
        bindings.vertex_buffers[0] = self.vertex_buffer;
        bindings.index_buffer = self.index_buffer;
        sg.applyBindings(bindings);
        sg.applyUniforms(shader.UB_vs_params, sg.asRange(&vs_params));

        // Apply scissor if active
        if (self.scissor_active) {
            sg.applyScissorRect(self.scissor_rect.x, self.scissor_rect.y, self.scissor_rect.w, self.scissor_rect.h, true);
        }

        // Draw indexed triangles
        sg.draw(0, @intCast(self.index_count), 1);

        // Reset scissor if it was active
        if (self.scissor_active) {
            sg.applyScissorRect(0, 0, 0, 0, false);
        }

        // Reset batch
        self.vertex_count = 0;
        self.index_count = 0;
    }

    /// Start scissor mode
    pub fn beginScissor(self: *Renderer, x: f32, y: f32, width: f32, height: f32) void {
        // Flush current batch before changing scissor state
        self.flushBatch();

        self.scissor_active = true;
        self.scissor_rect = .{
            .x = @intFromFloat(@round(x)),
            .y = @intFromFloat(@round(y)),
            .w = @intFromFloat(@round(width)),
            .h = @intFromFloat(@round(height)),
        };
    }

    /// End scissor mode
    pub fn endScissor(self: *Renderer) void {
        if (self.scissor_active) {
            // Flush current batch before changing scissor state
            self.flushBatch();
            self.scissor_active = false;
        }
    }

    /// Called at the end of frame to ensure all batched data is rendered
    pub fn finishFrame(self: *Renderer) void {
        self.flushBatch();
    }

    /// Update screen dimensions (call when window is resized)
    pub fn updateScreenSize(self: *Renderer, width: f32, height: f32) void {
        self.screen_width = width;
        self.screen_height = height;

        const target_width_f32 = @as(f32, @floatFromInt(self.target_width));
        const target_height_f32 = @as(f32, @floatFromInt(self.target_height));

        const target_aspect_ratio = target_width_f32 / target_height_f32;
        const aspect_ratio = width / height;

        if (aspect_ratio > target_aspect_ratio) {
            // Screen is wider than the ideal so use ideal height
            self.canvas_height = self.target_height;
            // and scale width up to a maximum of twice the target width
            self.canvas_width = @intFromFloat(@round(@min(aspect_ratio * target_height_f32, 2.0 * target_width_f32)));
        } else if (aspect_ratio < target_aspect_ratio) {
            // Screen is taller than the ideal so use ideal width
            self.canvas_width = self.target_width;
            // and scale height up to a maximum of twice the target height
            self.canvas_height = @intFromFloat(@round(@min(target_width_f32 / aspect_ratio, 2.0 * target_height_f32)));
        } else {
            // The aspect ratios match
            self.canvas_width = self.target_width;
            self.canvas_height = self.target_height;
        }

        // Assert that canvas dimensions never exceed twice the target dimensions
        std.debug.assert(self.canvas_width <= 2 * self.target_width);
        std.debug.assert(self.canvas_height <= 2 * self.target_height);
    }
};

// Transpose a 4x4 matrix (for HLSL row-major layout)
fn transposeMatrix(m: Mat4) Mat4 {
    return Mat4{
        m[0], m[4], m[8],  m[12],
        m[1], m[5], m[9],  m[13],
        m[2], m[6], m[10], m[14],
        m[3], m[7], m[11], m[15],
    };
}

// Global renderer instance and Clay state
pub var renderer: ?Renderer = null;
pub var clay_state: ?ClayState = null;

/// Initialize the renderer with Clay UI system
pub fn init(allocator: std.mem.Allocator, screen_width: f32, screen_height: f32) !void {
    renderer = Renderer.init(@intFromFloat(screen_width), @intFromFloat(screen_height));
    clay_state = try ClayState.init(allocator, screen_width, screen_height);
}

/// Cleanup resources, calling optional cleanup function first
/// Note: Sokol resources are automatically cleaned up when sg.shutdown() is called
pub fn deinit() void {
    // Then clean up renderer resources
    if (clay_state) |*state| {
        state.deinit();
        clay_state = null;
    }
    renderer = null;
}

/// Clay UI integration state
const ClayState = struct {
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

    pub fn endLayout(self: *ClayState) []clay.RenderCommand {
        _ = self;
        return clay.endLayout();
    }

    pub fn setPointerState(self: *ClayState, x: f32, y: f32, mouse_down: bool) void {
        _ = self;
        clay.setPointerState(.{ .x = x, .y = y }, mouse_down);
    }

    pub fn updateLayoutDimensions(self: *ClayState, screen_width: f32, screen_height: f32) void {
        _ = self;
        clay.setLayoutDimensions(.{ .w = screen_width, .h = screen_height });
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

/// Convert a clay color to Color format
pub fn clayColorToColor(color: clay.Color) Color {
    return Color.fromClayColor(color);
}

/// End UI layout and render - convenience wrapper
pub fn endLayout() void {
    if (clay_state) |*state| {
        const render_commands = state.endLayout();
        renderUI(render_commands);
    }
}

/// Set pointer/mouse state - convenience wrapper
pub fn setPointerState(x: f32, y: f32, mouse_down: bool) void {
    if (clay_state) |*state| {
        state.setPointerState(x, y, mouse_down);
    }
}

/// Update screen dimensions when window is resized
pub fn updateScreenSize(width: f32, height: f32) void {
    if (renderer) |*r| {
        r.updateScreenSize(width, height);
    }
    if (clay_state) |*state| {
        state.updateLayoutDimensions(width, height);
    }
}

/// Renders a frame, ensuring UI layout calls are observerd and rendered last
pub fn renderFrame(frame_fn: ?*const fn () void) void {
    clay.beginLayout();
    if (frame_fn) |callable| {
        callable();
    }
    if (clay_state) |*state| {
        renderUI(state.endLayout());
    }
}

/// Handle rendering a clay command array
pub fn renderUI(render_commands: []clay.RenderCommand) void {
    if (renderer == null) {
        return;
    }

    var sokol_renderer = &renderer.?;

    for (render_commands) |command| {
        const bbox = command.bounding_box;

        switch (command.command_type) {
            .none => {},

            .rectangle => {
                // Get the actual background color from the render data
                const rect_data = command.render_data.rectangle;
                const color = clayColorToColor(rect_data.background_color);
                sokol_renderer.drawRect(bbox.x, bbox.y, bbox.width, bbox.height, color);
            },

            .text => {
                // Use default colors for now since config access is not available
                const bg_color = Color.rgba(51, 51, 51, 255); // Dark gray for text background
                sokol_renderer.drawRect(bbox.x, bbox.y, bbox.width, bbox.height, bg_color);
            },

            .image => {
                // Placeholder for image rendering
                const color = Color.rgba(128, 128, 128, 255);
                sokol_renderer.drawRect(bbox.x, bbox.y, bbox.width, bbox.height, color);
            },

            .scissor_start => {
                sokol_renderer.beginScissor(bbox.x, bbox.y, bbox.width, bbox.height);
            },

            .scissor_end => {
                sokol_renderer.endScissor();
            },

            .border => {
                // Get the actual border data from the render command
                const border_data = command.render_data.border;
                const color = clayColorToColor(border_data.color);

                // Use actual border widths from the data
                const top_width = @as(f32, @floatFromInt(border_data.width.top));
                const bottom_width = @as(f32, @floatFromInt(border_data.width.bottom));
                const left_width = @as(f32, @floatFromInt(border_data.width.left));
                const right_width = @as(f32, @floatFromInt(border_data.width.right));

                // Top border
                if (top_width > 0) {
                    sokol_renderer.drawRect(bbox.x, bbox.y, bbox.width, top_width, color);
                }
                // Bottom border
                if (bottom_width > 0) {
                    sokol_renderer.drawRect(bbox.x, bbox.y + bbox.height - bottom_width, bbox.width, bottom_width, color);
                }
                // Left border
                if (left_width > 0) {
                    sokol_renderer.drawRect(bbox.x, bbox.y, left_width, bbox.height, color);
                }
                // Right border
                if (right_width > 0) {
                    sokol_renderer.drawRect(bbox.x + bbox.width - right_width, bbox.y, right_width, bbox.height, color);
                }
            },

            .custom => {
                // Custom render commands not implemented
            },
        }
    }

    // Flush any remaining batched data
    sokol_renderer.finishFrame();
}
