const std = @import("std");
const cairo = @import("cairo");

pub const ImageSurface = struct {
    const Self = @This();
    const Err = error{
        FAILED_TO_CREATE_SURFACE,
    };

    allocator: std.mem.Allocator,
    surface: *cairo.Surface,
    data: []u32,
    width: u32,
    height: u32,

    pub fn new(allocator: std.mem.Allocator, width: u32, height: u32) !Self {
        const data = try allocator.alloc(u32, @intCast(width * height));
        errdefer allocator.free(data);

        const surface = cairo.imageSurfaceCreateForData(@ptrCast(&data[0]), cairo.FORMAT_ARGB32, @intCast(width), @intCast(height), @intCast(4 * width)) orelse return Err.FAILED_TO_CREATE_SURFACE;
        return Self{
            .allocator = allocator,
            .surface = surface,
            .data = data,
            .width = width,
            .height = height,
        };
    }

    pub fn resize(self: *Self, width: u32, height: u32) !void {
        if(width == 0 or height == 0) return;
        self.width = width;
        self.height = height;
        self.destroy();

        self.data = try self.allocator.alloc(u32, @intCast(width * height));
        errdefer self.allocator.free(self.data);
        

        self.surface = cairo.imageSurfaceCreateForData(@ptrCast(&self.data[0]), cairo.FORMAT_ARGB32, @intCast(width), @intCast(height), @intCast(4 * width)) orelse return Err.FAILED_TO_CREATE_SURFACE;
    }

    pub fn destroy(self: Self) void {
        // data is allocated by the cairo library using malloc
        std.c.free(self.surface);
        self.allocator.free(self.data);
    }
};

pub const Graphics = struct {
    const Self = @This();
    const Err = error{
        FAILED_TO_CREATE_CAIRO_CONTEXT,
        FAILED_TO_RESIZE_SURFACE,
    };

    allocator: std.mem.Allocator,
    ctx: *cairo.Context,
    _surface: []ImageSurface,
    surface: *ImageSurface,

    pub fn new(allocator: std.mem.Allocator, width: u32, height: u32) !Self {
        const _surface = try allocator.alloc(ImageSurface, 1);
        const surface = &_surface[0];
        surface.* = try ImageSurface.new(allocator, width, height);

        const ctx = cairo.create(surface.surface) orelse return Err.FAILED_TO_CREATE_CAIRO_CONTEXT;

        return Self{
            .allocator = allocator,
            .surface = surface,
            ._surface = _surface,
            .ctx = ctx,
        };
    }

    pub fn resize(self: *Self, width: u32, height: u32) Err!void {
        cairo.destroy(self.ctx);
        self.surface.resize(width, height) catch return Err.FAILED_TO_RESIZE_SURFACE;
        self.ctx = cairo.create(self.surface.surface) orelse return Err.FAILED_TO_CREATE_CAIRO_CONTEXT;
    }

    pub fn destroy(self: Self) void {
        cairo.destroy(self.ctx);
        self.surface.destroy();
        self.allocator.free(self._surface);
    }

    pub fn clear(self: Self) void {
        self.rectangle(0, 0, @floatFromInt(self.surface.width), @floatFromInt(self.surface.height));
        self.fill();
    }

    pub fn setSourceRGB(self: Self, r: f32, g: f32, b: f32) void {
        cairo.setSourceRGB(self.ctx, r, g, b);
    }

    pub fn rectangle(self: Self, x: f32, y: f32, width: f32, height: f32) void {
        cairo.rectangle(self.ctx, x, y, width, height);
    }

    pub fn fill(self: Self) void {
        cairo.fill(self.ctx);
    }
};

const testing = @import("std").testing;
test "create_graphics" {
    const graphics = try Graphics.new(testing.allocator, 640, 640);
    defer graphics.destroy();
}

test "resize_graphics" {
    var graphics = try Graphics.new(testing.allocator, 640, 640);
    defer graphics.destroy();

    try graphics.resize(320, 320);
    try testing.expect(graphics.surface.width == 320);
    try testing.expect(graphics.surface.height == 320);
}
