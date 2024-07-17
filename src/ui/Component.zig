context: *const anyopaque,
parent: ?*Self,
children: std.ArrayList(*Self),
invalid: bool,

update: *const fn (*const anyopaque) anyerror!void,
sync: *const fn (*const anyopaque, *context.Graphics) anyerror!void,

const std = @import("std");
const context = @import("../context.zig");
const Self = @This();
