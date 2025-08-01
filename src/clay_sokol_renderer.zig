const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
const clay = @import("zclay");
const shader = @import("shader.zig");
const pxl = @import("pixelometry.zig");

// Matrix type for 4x4 transformation matrix
const Mat4 = [16]f32;

/// Font wrapper for Sokol renderer
pub const Font = struct {
    /// Font ID for clay
    id: u32,
    /// Font size for measurement (we'll use a simple approximation for now)
    base_size: f32,
    /// Character width approximation
    char_width_ratio: f32,
};

/// Global font list
pub var fonts: ?std.ArrayList(Font) = null;

/// Simple vertex structure for 2D rendering
const Vertex = struct {
    pos: [2]f32,
    color: [4]f32,
};

// Create a 2D orthographic projection matrix with top-left origin fix
fn createOrthoMatrix(left: f32, right: f32, top: f32, bottom: f32) Mat4 {
    const width = right - left;
    const height = bottom - top;

    return Mat4{
        2.0 / width, 0.0, 0.0, -(right + left) / width,
        0.0, 2.0 / height, 0.0,  (bottom + top) / height, // Flip Y translation
        0.0, 0.0,          -1.0, 0.0,
        0.0, 0.0,          0.0,  1.0,
    };
}

// Transpose a 4x4 matrix (for HLSL row-major layout)
fn transposeMatrix(m: Mat4) Mat4 {
    return Mat4{
        m[0], m[4], m[8],  m[12],
        m[1], m[5], m[9],  m[13],
        m[2], m[6], m[10], m[14],
        m[3], m[7], m[11], m[15],
    };
}

/// Render state for the Sokol backend with actual GPU rendering
pub const SokolRenderer = struct {
    /// Screen dimensions
    screen_width: f32,
    screen_height: f32,
    /// GPU resources
    shader_program: sg.Shader,
    vertex_buffer: sg.Buffer,
    index_buffer: sg.Buffer,
    pipeline: sg.Pipeline,
    /// Vertex data staging
    vertices: [1024]Vertex, // Static buffer for vertices
    indices: [1536]u16, // Static buffer for indices (6 per rectangle: 2 triangles)
    vertex_count: u32,
    index_count: u32,
    /// Current scissor state
    scissor_active: bool,
    scissor_rect: struct { x: i32, y: i32, w: i32, h: i32 },

    pub fn init(screen_width: f32, screen_height: f32) SokolRenderer {

        // Create shader
        const shd = sg.makeShader(shader.pixelShaderDesc(sg.queryBackend()));

        // Create vertex buffer (dynamic for UI rendering)
        const vbuf = sg.makeBuffer(.{
            .size = @sizeOf(Vertex) * 1024,
            .usage = .{ .vertex_buffer = true, .stream_update = true },
            .label = "clay-vertices",
        });

        // Create index buffer (dynamic for UI rendering)
        const ibuf = sg.makeBuffer(.{
            .size = @sizeOf(u16) * 1536,
            .usage = .{ .index_buffer = true, .stream_update = true },
            .label = "clay-indices",
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
            .label = "clay-pipeline",
        });

        return SokolRenderer{
            .screen_width = screen_width,
            .screen_height = screen_height,
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

    /// Convert screen coordinates to normalized device coordinates
    fn screenToNDC(self: *const SokolRenderer, x: f32, y: f32) [2]f32 {
        return .{
            (x * 2.0 / self.screen_width) - 1.0,
            1.0 - (y * 2.0 / self.screen_height),
        };
    }

    /// Add a rectangle to the batch for rendering
    pub fn drawRect(self: *SokolRenderer, x: f32, y: f32, width: f32, height: f32, color: pxl.Color) void {
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
    pub fn flushBatch(self: *SokolRenderer) void {
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
    pub fn beginScissor(self: *SokolRenderer, x: f32, y: f32, width: f32, height: f32) void {
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
    pub fn endScissor(self: *SokolRenderer) void {
        if (self.scissor_active) {
            // Flush current batch before changing scissor state
            self.flushBatch();
            self.scissor_active = false;
        }
    }

    /// Called at the end of frame to ensure all batched data is rendered
    pub fn finishFrame(self: *SokolRenderer) void {
        self.flushBatch();
    }
};

/// Global renderer instance
pub var renderer: ?SokolRenderer = null;

/// Convert a clay color to pxl.Color format
pub fn clayColorToPxlColor(color: clay.Color) pxl.Color {
    return pxl.Color.fromClayColor(color);
}

/// Callback for clay to get the dimensions of text data
pub fn measureText(text: []const u8, config: *clay.TextElementConfig, user_data: void) clay.Dimensions {
    _ = user_data;

    if (fonts == null) {
        return .{ .w = 0, .h = 0 };
    }

    if (config.font_id >= fonts.?.items.len) {
        return .{ .w = 0, .h = 0 };
    }

    const font = fonts.?.items[config.font_id];
    const scale_factor = @as(f32, @floatFromInt(config.font_size)) / font.base_size;

    // Simple text measurement (you might want to implement proper font metrics)
    var max_width: f32 = 0;
    var current_width: f32 = 0;
    var line_count: u32 = 1;

    for (text) |char| {
        if (char == '\n') {
            max_width = @max(max_width, current_width);
            current_width = 0;
            line_count += 1;
        } else {
            current_width += @as(f32, @floatFromInt(config.font_size)) * font.char_width_ratio;
        }
    }

    max_width = @max(max_width, current_width);

    return .{
        .w = max_width * scale_factor,
        .h = @as(f32, @floatFromInt(config.font_size)) * @as(f32, @floatFromInt(line_count)),
    };
}

/// Initialize the clay-sokol renderer with the given screen dimensions
pub fn initialize(screen_width: f32, screen_height: f32, allocator: std.mem.Allocator) !void {
    // Initialize fonts list
    fonts = std.ArrayList(Font).init(allocator);

    // Add a default font
    try fonts.?.append(.{
        .id = 0,
        .base_size = 16.0,
        .char_width_ratio = 0.6, // Approximate character width ratio
    });

    // Initialize renderer
    renderer = SokolRenderer.init(screen_width, screen_height);
}

/// Cleanup resources
pub fn deinitialize() void {
    if (fonts) |*font_list| {
        font_list.deinit();
        fonts = null;
    }
    // Note: Sokol resources are automatically cleaned up when sg.shutdown() is called
}

/// Reset per-frame counters - should be called at the start of each frame
pub fn startFrame() void {
    // Reset per-frame counters if needed
}

/// Handle rendering a clay command array
pub fn render(render_commands: []clay.RenderCommand) void {
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
                const color = clayColorToPxlColor(rect_data.background_color);
                sokol_renderer.drawRect(bbox.x, bbox.y, bbox.width, bbox.height, color);
            },

            .text => {
                // Use default colors for now since config access is not available
                const bg_color = pxl.Color.rgba(51, 51, 51, 255); // Dark gray for text background
                sokol_renderer.drawRect(bbox.x, bbox.y, bbox.width, bbox.height, bg_color);
            },

            .image => {
                // Placeholder for image rendering
                const color = pxl.Color.rgba(128, 128, 128, 255);
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
                const color = clayColorToPxlColor(border_data.color);

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

/// Update screen dimensions (call when window is resized)
pub fn updateScreenSize(width: f32, height: f32) void {
    if (renderer) |*r| {
        r.screen_width = width;
        r.screen_height = height;
    }
}
