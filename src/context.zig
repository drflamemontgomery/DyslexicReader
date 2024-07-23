const std = @import("std");
const cairo = @import("cairo");
const Component = @import("ui/ui.zig").Component;

pub const Context = struct {
    const Self = @This();

    component: Component,

    pub fn new(allocator: std.mem.Allocator) Self {
        var self = Self{
            .component = undefined,
        };
        const component = Component{
            .context = &self,
            .children = std.ArrayList(*Component).init(allocator),
            .update = update,
            .sync = sync,
        };

        self.component = component;
        return self;
    }

    pub fn update(component: *Component) !void {
        for (component.children.items) |child| {
            try update(child);
            try child.update(child);
        }
    }

    pub fn _sync(component: *Component, graphics: *Graphics) anyerror!void {
        for (component.children.items) |child| {
            try child.sync(child, graphics);
            try _sync(child, graphics);
        }
    }

    pub fn sync(component: *Component, graphics: *Graphics) anyerror!void {
        if (component.invalid) {
            graphics.setSourceRGB(0, 0, 0);
            graphics.clear();
            component.invalid = false;
        }

        try _sync(component, graphics);
    }

    pub fn destroy(self: *Self) void {
        self.component.destroy();
    }
};

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
        if (width == 0 or height == 0) return;
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

const ft = @import("ft.zig");

pub const Graphics = struct {
    const Self = @This();
    const Err = error{
        FAILED_TO_CREATE_CAIRO_CONTEXT,
        FAILED_TO_RESIZE_SURFACE,
    };
    var FontLib:?ft.Library = null;

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
        if (width == 0 or height == 0) return;
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

    pub fn setFontFace(self: Self, font_face:*ft.Face) void {
        cairo.setFontFace(self.ctx, @ptrCast(font_face));
    }

    pub fn showGlyphs(self: Self, glyphs: []ft.Glyph) !void {
        const glyph_array: []cairo.Glyph = try self.allocator.alloc(cairo.Glyph, glyphs.len);
        defer self.allocator.free(glyph_array);

        for(glyphs, 0..) |glyph, i| {
            glyph_array[i] = .{
                .x = glyph.x,
                .y = glyph.y,
                .index = glyph.index,
            };
        }

        cairo.showGlyphs(self.ctx, @ptrCast(glyph_array), @intCast(glyphs.len));
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

test "create_root_component" {
    var graphics = try Graphics.new(std.testing.allocator, 320, 320);
    defer graphics.destroy();

    var root = Context.new(std.testing.allocator);
    defer root.destroy();

    try testing.expect(root.component.children.items.len == 0);

    try Context.update(&root.component);
    try Context.sync(&root.component, &graphics);
}

test "create_text_components" {
    const ui = @import("ui/ui.zig");
    _ = try ft.Library.init();

    var graphics = try Graphics.new(std.testing.allocator, 320, 320);
    defer graphics.destroy();

    var root = Context.new(std.testing.allocator);
    defer root.destroy();

    try testing.expect(root.component.children.items.len == 0);

    var text = try ui.Text.new(std.testing.allocator, "Hello");
    _ = try text.getComponent(std.testing.allocator, &root.component);

    try testing.expect(root.component.children.items.len == 1);

    const _text: *const ui.Text = @alignCast(@ptrCast(root.component.children.items[0].context));
    try testing.expect(std.mem.eql(u8, _text.text, "Hello"));

    std.debug.print("{any}\n", .{_text.glyphs});

    try Context.update(&root.component);
    try Context.sync(&root.component, &graphics);
}
