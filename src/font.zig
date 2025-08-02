const std = @import("std");
const sokol = @import("sokol");
const sg = sokol.gfx;
const zigimg = @import("zigimg");

/// Character information for bitmap font rendering
pub const CharInfo = struct {
    x: u32, // X position in the font texture
    y: u32, // Y position in the font texture
    width: u32, // Width of the character in pixels
    height: u32, // Height of the character in pixels
};

/// Bitmap font structure that integrates with Sokol for rendering
pub const Font = struct {
    // Texture dimensions (kept for UV calculations)
    image_width: u32,
    image_height: u32,

    // Sokol resources
    texture: sg.Image,
    sampler: sg.Sampler,

    // Character mapping
    char_map: std.AutoHashMap(u21, CharInfo), // UTF-8 codepoint to character info
    allocator: std.mem.Allocator,

    const Self = @This();

    /// Initialize a new Font with raw image data
    /// The character mapping must be populated separately using addChar()
    pub fn initWithData(allocator: std.mem.Allocator, image_data: []const u8, width: u32, height: u32) !Self {
        // Create Sokol texture and upload image data
        var image_data_struct: sg.ImageData = .{};
        image_data_struct.subimage[0][0] = .{ .ptr = image_data.ptr, .size = image_data.len };

        const texture = sg.makeImage(.{
            .width = @intCast(width),
            .height = @intCast(height),
            .pixel_format = .RGBA8,
            .data = image_data_struct,
            .label = "font_texture",
        });

        // Create sampler for texture filtering
        const sampler = sg.makeSampler(.{
            .min_filter = .NEAREST,
            .mag_filter = .NEAREST,
            .wrap_u = .CLAMP_TO_EDGE,
            .wrap_v = .CLAMP_TO_EDGE,
            .label = "font_sampler",
        });

        return Self{
            .image_width = width,
            .image_height = height,
            .texture = texture,
            .sampler = sampler,
            .char_map = std.AutoHashMap(u21, CharInfo).init(allocator),
            .allocator = allocator,
        };
    }

    /// Initialize a new Font by loading an image from disk using zigimg
    /// The character mapping must be populated separately using addChar()
    pub fn init(allocator: std.mem.Allocator, image_path: []const u8) !Self {
        // Load image using zigimg
        var image = zigimg.Image.fromFilePath(allocator, image_path) catch |err| {
            std.log.err("Failed to load image '{s}': {}", .{ image_path, err });
            return error.ImageLoadFailed;
        };
        defer image.deinit();

        // Convert to RGBA8 if needed
        try image.convert(.rgba32);

        const width = @as(u32, @intCast(image.width));
        const height = @as(u32, @intCast(image.height));

        // Get the raw pixel data
        const rgba_pixels = image.pixels.rgba32;
        const pixel_data = std.mem.sliceAsBytes(rgba_pixels);

        // Create font with the loaded data
        const font = try Self.initWithData(allocator, pixel_data, width, height);

        return font;
    }

    /// Create a dummy font for testing without image loading
    /// This creates a 1x1 white pixel texture for basic functionality
    pub fn initDummy(allocator: std.mem.Allocator) !Self {
        // Create a 1x1 white pixel for testing
        const dummy_data = [_]u8{ 255, 255, 255, 255 }; // White RGBA pixel

        return Self.initWithData(allocator, &dummy_data, 1, 1);
    }

    /// Cleanup resources
    pub fn deinit(self: *Self) void {
        self.char_map.deinit();
        sg.destroyImage(self.texture);
        sg.destroySampler(self.sampler);
    }

    /// Add a character mapping to the font
    /// codepoint: UTF-8 codepoint (e.g., 'A' = 65)
    /// x, y: Position in the texture (top-left coordinate system as per user preference)
    /// width, height: Dimensions of the character in pixels
    pub fn addChar(self: *Self, codepoint: u21, x: u32, y: u32, width: u32, height: u32) !void {
        try self.char_map.put(codepoint, CharInfo{
            .x = x,
            .y = y,
            .width = width,
            .height = height,
        });
    }

    /// Get character information for a UTF-8 codepoint
    pub fn getChar(self: *Self, codepoint: u21) ?CharInfo {
        return self.char_map.get(codepoint);
    }

    /// Convenience method to add ASCII characters in a grid layout
    /// This assumes characters are arranged in a regular grid starting from a given ASCII code
    /// start_char: First ASCII character (e.g., 32 for space)
    /// chars_per_row: Number of characters per row in the texture
    /// char_width, char_height: Dimensions of each character
    /// grid_x, grid_y: Starting position of the grid in the texture
    pub fn addASCIIGrid(self: *Self, start_char: u8, end_char: u8, chars_per_row: u32, char_width: u32, char_height: u32, grid_x: u32, grid_y: u32) !void {
        var char_code = start_char;
        while (char_code <= end_char) : (char_code += 1) {
            const char_index = char_code - start_char;
            const row = char_index / chars_per_row;
            const col = char_index % chars_per_row;

            const x = grid_x + col * char_width;
            const y = grid_y + row * char_height;

            try self.addChar(char_code, x, y, char_width, char_height);
        }
    }

    /// Get texture coordinates for a character (for use in shaders)
    /// Returns UV coordinates in the format [u_min, v_min, u_max, v_max] where:
    /// (u_min, v_min) is top-left corner, (u_max, v_max) is bottom-right corner
    pub fn getCharUV(self: *Self, codepoint: u21) ?[4]f32 {
        if (self.getChar(codepoint)) |char_info| {
            const u_min = @as(f32, @floatFromInt(char_info.x)) / @as(f32, @floatFromInt(self.image_width));
            const v_min = @as(f32, @floatFromInt(char_info.y)) / @as(f32, @floatFromInt(self.image_height));
            const u_max = @as(f32, @floatFromInt(char_info.x + char_info.width)) / @as(f32, @floatFromInt(self.image_width));
            const v_max = @as(f32, @floatFromInt(char_info.y + char_info.height)) / @as(f32, @floatFromInt(self.image_height));

            return .{ u_min, v_min, u_max, v_max };
        }
        return null;
    }

    /// Measure the width of a UTF-8 string using this font
    /// Returns the total width in pixels
    pub fn measureText(self: *Self, text: []const u8) f32 {
        var width: f32 = 0;
        var utf8_view = std.unicode.Utf8View.init(text) catch return 0;
        var utf8_iterator = utf8_view.iterator();

        while (utf8_iterator.nextCodepoint()) |codepoint| {
            if (self.getChar(codepoint)) |char_info| {
                width += @floatFromInt(char_info.width);
            }
        }

        return width;
    }

    /// Get the height of the font (maximum character height)
    /// This requires at least one character to be loaded
    pub fn getHeight(self: *Self) f32 {
        var max_height: u32 = 0;
        var iterator = self.char_map.valueIterator();

        while (iterator.next()) |char_info| {
            max_height = @max(max_height, char_info.height);
        }

        return @floatFromInt(max_height);
    }
};

/// Create a Font with a common ASCII character set from an image file
/// This is a convenience function for loading fonts with standard ASCII characters (32-126)
pub fn createASCIIFont(allocator: std.mem.Allocator, image_path: []const u8, chars_per_row: u32, char_width: u32, char_height: u32, grid_x: u32, grid_y: u32) !Font {
    var font = try Font.init(allocator, image_path);
    try font.addASCIIGrid(32, 126, chars_per_row, char_width, char_height, grid_x, grid_y);
    return font;
}

/// Create a dummy Font with a common ASCII character set for testing
/// This creates a font with fixed-width characters for layout testing
pub fn createDummyASCIIFont(allocator: std.mem.Allocator, char_width: u32, char_height: u32) !Font {
    var font = try Font.initDummy(allocator);
    try font.addASCIIGrid(32, 126, 95, char_width, char_height, 0, 0); // All characters in one row
    return font;
}
