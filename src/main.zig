const glfw = @import("glfw");
const std = @import("std");
const context = @import("context.zig");
const Context = context.Context;

pub fn main() !void {
    // Setup an ArenaAllocator so we can deallocate everything afterwards
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    // Initialize Our graphics context
    try Context.init();
    defer Context.terminate();

    var window = try Context.new(arena, "Dyslexic Reader", 1024, 786);
    defer window.destroy();

    // Make our window collect the current events
    window.makeCurrent();

    try mainLoop(arena, &window);
}

fn mainLoop(allocator: std.mem.Allocator, window: *Context) !void {
    _ = allocator;
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
