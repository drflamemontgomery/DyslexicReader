text: []const u8,

pub fn new(allocator:std.mem.Allocator, parent: ?*AnyComponent, text: []const u8) Component(Self, update, sync) {
    return .{
        .context = .{
            .text = text,

        },

        .parent = parent,
        .children = std.ArrayList(*AnyComponent).init(allocator),
        .invalid = true,
        .pos = .{
            .x = 0,
            .y = 0
        },
        .size = .{
            .width = 100,
            .height = 20,
        },
    };
}

pub fn update(self: *Self) anyerror!void {
    std.debug.print("[Text]: '{s}'\n", .{self.text});
}

pub fn sync(self: *Self, graphics:*Graphics) anyerror!void {
    _ = self;
    _ = graphics;
}

const std = @import("std");
const ui = @import("ui.zig");
const Component = ui.Component;
const AnyComponent = ui.AnyComponent;
const Graphics = @import("../context.zig").Graphics;
const Self = @This();
