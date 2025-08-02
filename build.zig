const std = @import("std");
const Build = std.Build;
const sokol = @import("sokol");

const Options = struct {
    mod: *Build.Module,
    dep_sokol: *Build.Dependency,
};

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const dep_sokol = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
    });
    const dep_zclay = b.dependency("zclay", .{
        .target = target,
        .optimize = optimize,
    });
    const dep_zigimg = b.dependency("zigimg", .{
        .target = target,
        .optimize = optimize,
    });
    const dep_sokol_tools = b.dependency("sokol_tools", .{});

    // Compile shaders
    const shader_step = compileShaders(b, dep_sokol_tools);

    // Create the pixelometry library module
    const mod_pixelometry = b.createModule(.{
        .root_source_file = b.path("src/pixelometry.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
            .{ .name = "zclay", .module = dep_zclay.module("zclay") },
            .{ .name = "zigimg", .module = dep_zigimg.module("zigimg") },
        },
    });

    // Add C include path for stb_image
    mod_pixelometry.addIncludePath(b.path("src/c"));

    // Build and install the pixelometry library as the default build step
    const lib = b.addStaticLibrary(.{
        .name = "pixelometry",
        .root_module = mod_pixelometry,
    });
    lib.step.dependOn(shader_step);
    b.installArtifact(lib);

    // Create examples
    const examples = [_]struct { name: []const u8, file: []const u8 }{
        .{ .name = "basic", .file = "examples/basic.zig" },
        .{ .name = "clay", .file = "examples/clay.zig" },
    };

    // Default example (basic)
    const mod_example = b.createModule(.{
        .root_source_file = b.path("examples/basic.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "pixelometry", .module = mod_pixelometry },
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
        },
    });

    // special case handling for native vs web build
    const opts = Options{ .mod = mod_example, .dep_sokol = dep_sokol };
    if (target.result.cpu.arch.isWasm()) {
        try buildWeb(b, opts);
    } else {
        try buildNative(b, opts);
    }

    // Create individual example executables (only for native builds)
    if (!target.result.cpu.arch.isWasm()) {
        inline for (examples) |example| {
            const mod = b.createModule(.{
                .root_source_file = b.path(example.file),
                .target = target,
                .optimize = optimize,
                .imports = &.{
                    .{ .name = "pixelometry", .module = mod_pixelometry },
                    .{ .name = "sokol", .module = dep_sokol.module("sokol") },
                },
            });

            const exe = b.addExecutable(.{
                .name = example.name,
                .root_module = mod,
            });
            b.installArtifact(exe);

            const run = b.addRunArtifact(exe);
            const run_step = b.step("run-" ++ example.name, "Run " ++ example.name ++ " example");
            run_step.dependOn(&run.step);
        }
    }
}

// this is the regular build for all native platforms
fn buildNative(b: *Build, opts: Options) !void {
    const exe = b.addExecutable(.{
        .name = "pixelometry",
        .root_module = opts.mod,
    });
    b.installArtifact(exe);
    const run = b.addRunArtifact(exe);
    b.step("run", "Run pixelometry").dependOn(&run.step);
}

// for web builds, the Zig code needs to be built into a library and linked with the Emscripten linker
fn buildWeb(b: *Build, opts: Options) !void {
    const lib = b.addLibrary(.{
        .name = "pixelometry",
        .root_module = opts.mod,
    });

    // create a build step which invokes the Emscripten linker
    const emsdk = opts.dep_sokol.builder.dependency("emsdk", .{});
    const link_step = try sokol.emLinkStep(b, .{
        .lib_main = lib,
        .target = opts.mod.resolved_target.?,
        .optimize = opts.mod.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = false,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });
    // attach Emscripten linker output to default install step
    b.getInstallStep().dependOn(&link_step.step);
    // ...and a special run step to start the web build output via 'emrun'
    const run = sokol.emRunStep(b, .{ .name = "pixelometry", .emsdk = emsdk });
    run.step.dependOn(&link_step.step);
    b.step("run", "Run pixelometry").dependOn(&run.step);
}

// Compile shaders using sokol-shdc
fn compileShaders(b: *Build, dep_sokol_tools: *Build.Dependency) *Build.Step {
    const shdc_step = b.step("shaders", "Compile shaders");

    // Compile pixel.glsl shader using precompiled sokol-shdc binary
    const shdc_binary_path = dep_sokol_tools.path("bin/osx/sokol-shdc").getPath(b);
    const pixel_shader_cmd = b.addSystemCommand(&.{shdc_binary_path});
    pixel_shader_cmd.addArgs(&.{
        "--input",  "shaders/pixel.glsl",
        "--output", "src/shader.zig",
        "--slang",  "glsl410:hlsl5:metal_macos",
        "--format", "sokol_zig",
    });

    // Compile text.glsl shader using precompiled sokol-shdc binary
    const text_shader_cmd = b.addSystemCommand(&.{shdc_binary_path});
    text_shader_cmd.addArgs(&.{
        "--input",  "shaders/text.glsl",
        "--output", "src/text_shader.zig",
        "--slang",  "glsl410:hlsl5:metal_macos",
        "--format", "sokol_zig",
    });

    shdc_step.dependOn(&pixel_shader_cmd.step);
    shdc_step.dependOn(&text_shader_cmd.step);
    return shdc_step;
}
