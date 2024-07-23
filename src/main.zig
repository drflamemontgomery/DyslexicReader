const glfw = @import("glfw");
const std = @import("std");
const winapi = @import("window.zig");
const Window = winapi.Window;

pub fn main() !void {
    // Setup an ArenaAllocator so we can deallocate everything afterwards
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    // Initialize Our window context
    try Window.init();
    defer Window.terminate();

    var window = try Window.new(arena, "Dyslexic Reader", 1024, 768);
    defer window.destroy();
    try window.resize(1024, 768);

    Window.current = &window;

    try mainLoop(arena, &window);
}

fn mainLoop(allocator: std.mem.Allocator, window: *Window) !void {
    const ui = @import("ui/ui.zig");

    var text = try ui.Text.new(allocator, "Hello World!");
    _ = try text.getComponent(allocator, &window.ctx.component);

    var text2 = try ui.Text.new(allocator, "Tryial!");
    _ = try text2.getComponent(allocator, &window.ctx.component);

    text.destroy();

    while (!window.shouldClose()) {


        try window.update();
    }
}
