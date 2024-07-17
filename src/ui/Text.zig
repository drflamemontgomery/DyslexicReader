text: []const u8,
component: ?Component = null,

pub fn new( text: []const u8) Self {
    return Self{
        .text = text,
    };
}

pub fn getComponent(self: *Self, allocator: std.mem.Allocator, parent: ?*Component) !Component {
    if(self.component == null) {
        self.component = Component {
            .context = @ptrCast(self),
            .parent = parent,
            .children = std.ArrayList(*Component).init(allocator),
            .update = update,
            .sync = sync,
        };
        if(parent) |p| {
            try p.addChild(&self.component.?);
        }
    }

    return self.component.?;
}

pub fn update(component: *Component) anyerror!void {
    const self: *const Self = @alignCast(@ptrCast(component.context));
    if(component.invalid) {
        std.debug.print("[Text]: {s}\n", .{self.text});
        component.invalid = false;
    }
}

pub fn sync(component: *Component, graphics: *Graphics) anyerror!void {
    _ = component;
    _ = graphics;
}

pub fn destroy(self: *Self) void {
    if(self.component) |*component| {
        component.destroy();
    }
    self.component = null;
}

const std = @import("std");
const ui = @import("ui.zig");
const Component = ui.Component;
const Graphics = @import("../context.zig").Graphics;
const Self = @This();
