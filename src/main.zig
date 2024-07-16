const glfw = @import("glfw");
const std = @import("std");
const context = @import("context.zig");
const Context = context.Context;

pub fn main() !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();

    const arena = arena_state.allocator();

    try Context.init();
    defer Context.terminate();

    var window = try Context.new(arena, "Test", 640, 640);
    defer window.destroy();

    window.makeCurrent();

    while (!window.shouldClose()) {
        window.graphics.setSourceRGB(0, 0, 0);
        window.graphics.clear();

        window.graphics.setSourceRGB(1, 0, 0);
        window.graphics.rectangle(32, 32, 32, 32);
        window.graphics.fill();

        window.render();
        window.swapBuffers();
        Context.pollEvents();
    }
}
