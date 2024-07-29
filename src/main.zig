const glfw = @import("glfw");
const std = @import("std");
const ui = @import("ui/ui.zig");
const Window = @import("window.zig").Window;
const ScaledFont = @import("graphics.zig").ScaledFont;

pub fn main() !void {
    // Setup an ArenaAllocator so we can deallocate everything afterwards
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    // Init our ScaledFont to handle our fonts and sizes.
    ScaledFont.init(arena);
    defer ScaledFont.deinit();

    // Initialize Our window context
    try Window.init();
    defer Window.terminate();

    var window = try Window.new(arena, "Dyslexic Reader", 1024, 768);
    defer window.destroy();

    // resize our window to build our context
    try window.resize(1024, 768);

    Window.current = &window;

    try mainLoop(arena, &window);
}

fn mainLoop(allocator: std.mem.Allocator, window: *Window) !void {
    var text = try ui.Text.new(allocator, "Hello World!");

    // Create the Text Component with the Window Component as a parent
    _ = try text.getComponent(allocator, &window.ctx.component);

    while (!window.shouldClose()) {
        try window.update();
    }
}
