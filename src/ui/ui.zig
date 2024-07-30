const std = @import("std");
const Graphics = @import("../graphics.zig").Graphics;

pub fn Position(comptime T: type) type {
    return struct {
        x: T,
        y: T,
    };
}

pub fn Size(comptime T: type) type {
    return struct {
        width: T,
        height: T,
    };
}

pub const Component = @import("Component.zig");
pub const Text = @import("Text.zig");
