context: *const anyopaque,
parent: ?*Self = null,
children: std.ArrayList(*Self),
invalid: bool = true,

pos: Position(f32) = .{ .x = 0, .y = 0 },
size: ?Size(f32) = null,

update: *const fn (*Self) anyerror!void,
sync: *const fn (*Self, *context.Graphics) anyerror!void,

pub fn addChild(self: *Self, child: *Self) !void {
    try self.children.append(child);
}

pub fn addChildAt(self: *Self, child: *Self, i: usize) void {
    self.children.insert(i, child);
}

pub fn removeChild(self: *Self, c: *Self) bool {
    for (self.children.items, 0..) |child, i| {
        if (c == child) {
            _ = self.children.orderedRemove(i);
            return true;
        }
    }
    return false;
}

pub fn destroy(self: *Self) void {
    if (self.parent) |p| {
        _ = p.removeChild(self);
    }

    for (self.children.items) |child| {
        child.destroy();
    }
    self.children.deinit();
}

const std = @import("std");
const context = @import("../context.zig");
const Self = @This();
const Position = @import("ui.zig").Position;
const Size = @import("ui.zig").Size;