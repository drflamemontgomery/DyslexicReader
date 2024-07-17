const std = @import("std");
const Graphics = @import("../context.zig").Graphics;

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

pub fn Component(comptime Context: type, comptime updateFn: fn (*Context) anyerror!void, comptime syncFn: fn (*Context, *Graphics) anyerror!void) type {
    return struct {
        const Self = @This();
        pub const T = Context;

        context: Context,

        parent: ?*AnyComponent,
        children: std.ArrayList(*AnyComponent),

        invalid: bool,
        pos: Position(f32),
        // if Size == null then it is max size
        size: ?Size(f32),

        pub fn addChild(self: *Self, child: *AnyComponent) void {
            self.children.append(child);
        }

        pub fn addChildAt(self: *Self, child: *AnyComponent, i: usize) void {
            self.children.insert(i, child);
        }

        pub fn removeChild(self: *Self, c: *AnyComponent) bool {
            for (self.children, 0..) |child, i| {
                if (c == child) {
                    self.children.orderedRemove(i);
                    return true;
                }
            }
            return false;
        }

        pub fn destroy(self: *Self) void {
            if (self.parent) |p| {
                p.removeChild(self);
            }

            for (self.children) |*child| {
                child.destroy();
            }
            self.children.deinit();
        }

        pub fn any(self: *const Self) AnyComponent {
            return .{
                .context = @ptrCast(&self.context),
                .parent = self.parent,
                .children = self.children,
                .invalid = self.invalid,

                .update = typeErasedUpdateFn,
                .sync = typeErasedSyncFn,
            };
        }

        fn typeErasedUpdateFn(context: *const anyopaque) anyerror!void {
            const ptr: *Context = @constCast(@alignCast(@ptrCast(context)));
            try updateFn(ptr);
        }

        fn typeErasedSyncFn(context: *const anyopaque, graphics: *Graphics) anyerror!void {
            const ptr: *Context = @constCast(@alignCast(@ptrCast(context)));
            try syncFn(ptr, graphics);
        } 
    };
}

pub const AnyComponent = @import("Component.zig");
const _Text = @import("Text.zig");
pub const Text = Component(_Text, _Text.update, _Text.sync);
