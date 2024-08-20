const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "dyslexic",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibC();

    const glfw_dep = b.dependency("mach_glfw", .{
        .target = target,
        .optimize = optimize,
    });

    const gl_bindings = @import("zigglgen").generateBindingsModule(b, .{
        .api = .gl,
        .version = .@"2.0",
        .extensions = &.{ .ARB_multi_bind, .ARB_compatibility, .ARB_multitexture, .EXT_texture, .ARB_texture_rectangle },
    });

    const zig_ui_bindings = b.dependency("zig-ui", .{
        .target = target,
        .optimize = optimize, 
    });

    // ./generator gl 4.1 core ARB_multi_bind

    exe.root_module.addImport("gl", gl_bindings);
    exe.root_module.addImport("glfw", glfw_dep.module("mach-glfw"));
    exe.root_module.addImport("zig-ui", zig_ui_bindings.module("zig-ui"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/tests.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe_unit_tests.root_module.addImport("zig-ui", zig_ui_bindings.module("zig-ui"));

    exe_unit_tests.linkSystemLibrary("cairo");
    exe_unit_tests.linkSystemLibrary("freetype");
    exe_unit_tests.linkSystemLibrary("fontconfig");
    exe_unit_tests.linkLibC();

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
