const pxl = @import("pixelometry");

pub fn main() void {
    pxl.runApp(.{
        .title = "Custom Size Example",
        .width = 1024,
        .height = 768,
    }, .{
        // Using null callbacks - just shows the clear color
    });
}
