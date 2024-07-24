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
    var FontLib: ?ft.Library = null;

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

    pub fn save(self: Self) void {
        cairo.save(self.ctx);
    }

    pub fn restore(self: Self) void {
        cairo.restore(self.ctx);
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

    pub fn setFontFace(self: Self, font_face: *ft.Face) void {
        cairo.setFontFace(self.ctx, @ptrCast(font_face));
    }

    pub fn showGlyphs(self: Self, glyphs: []cairo.Glyph) void {
        cairo.showGlyphs(self.ctx, @ptrCast(glyphs), @intCast(glyphs.len));
    }

    pub fn showGlyphsRaw(self: Self, glyphs: GlyphArray) void {
        cairo.showGlyphs(self.ctx, @ptrCast(glyphs), @intCast(glyphs.len));
    }

    pub fn showGlyphsAt(self: Self, x: f64, y: f64, glyphs: []cairo.Glyph) void {
        var font_matrix: cairo.Matrix = undefined;
        cairo.getFontMatrix(self.ctx, &font_matrix);

        var translate_matrix: cairo.Matrix = undefined;
        cairo.matrixInitTranslate(&translate_matrix, x, y);

        var result: cairo.Matrix = undefined;
        cairo.matrixMultiply(&result, &font_matrix, &translate_matrix);

        cairo.setFontMatrix(self.ctx, &result);
        self.showGlyphs(glyphs);
    }

    pub fn setScaledFont(self: Self, scaled_font: ScaledFont) void {
        cairo.setScaledFont(self.ctx, scaled_font.scaled_font);
    }

    const Self = @This();
    const Err = error{
        FAILED_TO_CREATE_CAIRO_CONTEXT,
        FAILED_TO_RESIZE_SURFACE,
    };
};

pub const GlyphArray = struct {
    glyphs: []cairo.Glyph,
    allocator: std.mem.Allocator,

    pub fn fromGlyphs(allocator: std.mem.Allocator, text: []const u8) !Self {
        const glyph_array: []cairo.Glyph = try allocator.alloc(cairo.Glyph, text.len);

        return .{
            .glyphs = glyph_array,
            .allocator = allocator,
        };
    }

    pub fn render(self: Self, graphics: *Graphics) !void {
        graphics.showGlyphsRaw(self.glyphs);
    }

    pub fn destroy(self: Self) void {
        self.allocator.free(self.glyphs);
    }

    const Self = @This();
};

pub const ScaledFont = struct {
    var fonts: ScaledFontHashMap = undefined;

    scaled_font: *cairo.ScaledFont,

    pub fn init(allocator: std.mem.Allocator) void {
        fonts = ScaledFontHashMap.init(allocator);
    }

    pub fn deinit() void {
        fonts.deinit();
    }

    pub fn get(size: f64, font: []const u8) !Self {
        if (fonts.contains(.{ size, font })) {
            std.debug.print("Contains {} {s}\n", .{ size, font });
            return .{
                .scaled_font = fonts.get(.{ size, font }).?.ref,
            };
        }

        const face = try ft.Library.current.?.newFace(font, 0);
        const ft_font = cairo.ftFontFaceCreateForFTFace(face, 0).?;
        var key: cairo.UserDataKey = undefined;
        if (cairo.fontFaceSetUserData(ft_font, @ptrCast(&key), face, @ptrCast(&cairo.FT_Done_Face)) != 0) {
            cairo.fontFaceDestroy(ft_font);
            _ = cairo.FT_Done_Face(face);
            return Err.FAILED_TO_CREATE_FACE;
        }
        const scaled_font = try Self.new(ft_font, .{ .size = size });
        try fonts.put(.{ size, font }, .{ .ref = scaled_font.scaled_font });
        return scaled_font;
    }

    pub fn new(font: ?*cairo.FontFace, options: FontOptions) !Self {
        var font_matrix: cairo.Matrix = undefined;
        var ctm: cairo.Matrix = undefined;

        const font_options: *cairo.FontOptions = cairo.fontOptionsCreate() orelse return Err.FAILED_TO_CREATE_SCALED_FONT;
        defer cairo.fontOptionsDestroy(font_options);

        cairo.matrixInitScale(&font_matrix, @floatCast(options.size), @floatCast(options.size));
        cairo.matrixInitIdentity(&ctm);

        const scaled_font = cairo.scaledFontCreate(font, &font_matrix, &ctm, font_options) orelse return Err.FAILED_TO_CREATE_SCALED_FONT;

        return .{
            .scaled_font = scaled_font,
        };
    }

    pub fn textToGlyphs(self: Self, x: f64, y: f64, str: []const u8, glyphs: []cairo.Glyph) !usize {
        var _glyphs: *cairo.Glyph = &glyphs[0];
        var num_of_glyphs: c_int = @intCast(glyphs.len);

        if (cairo.scaledFontTextToGlyphs(self.scaled_font, @floatCast(x), @floatCast(y), @ptrCast(&str[0]), @intCast(str.len), @ptrCast(&_glyphs), &num_of_glyphs, @ptrFromInt(0), @ptrFromInt(0), @ptrFromInt(0)) != cairo.STATUS_SUCCESS) {
            return Err.FAILED_TO_CONVERT_TO_GLYPHS;
        }

        // if num_of_glyphs increased then cairo allocated its own array
        if (num_of_glyphs > @as(c_int, @intCast(glyphs.len))) {
            cairo.glyphFree(@ptrCast(_glyphs));
            return Err.FAILED_TO_CONVERT_TO_GLYPHS;
        }

        return @intCast(num_of_glyphs);
    }

    pub fn destroy(self: Self) void {
        cairo.scaledFontDestroy(self.scaled_font);
    }

    const Self = @This();
    const FontOptions = struct {
        size: f64 = 12,
    };
    const Err = error{
        FAILED_TO_CREATE_SCALED_FONT,
        FAILED_TO_CONVERT_TO_GLYPHS,
        FAILED_TO_GET_FONT,
        FAILED_TO_CREATE_FACE,
    };
    const ScaledFontRef = struct {
        ref: *cairo.ScaledFont,
    };

    const ScaledFontRefContext = struct {
        pub fn eql(self: @This(), a: ScaledFontRefKey, b: ScaledFontRefKey, b_index: usize) bool {
            _ = self;
            _ = b_index;
            return a[0] == b[0] and std.array_hash_map.eqlString(a[1], b[1]);
        }

        pub fn hash(self: @This(), a: ScaledFontRefKey) u32 {
            _ = self;
            return @as(u32, @intFromFloat(a[0])) + std.array_hash_map.hashString(a[1]);
        }
    };

    const ScaledFontRefKey = struct { f64, []const u8 };

    const ScaledFontHashMap = std.ArrayHashMap(ScaledFontRefKey, ScaledFontRef, ScaledFontRefContext, true);
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
