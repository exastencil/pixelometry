const pxl = @import("pixelometry");

pub fn main() void {
    pxl.runApp(.{
        .title = "Basic Example",
        .width = 800,
        .height = 600,
    }, .{});
}
