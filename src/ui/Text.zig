var initialized: bool = false;
var face: cairo.FT_Face = undefined;
var font: *cairo.FontFace = undefined;
var key: cairo.UserDataKey = undefined;

allocator: std.mem.Allocator,
text: []const u8,
glyphs: []ft.Glyph,
component: ?Component = null,

pub fn new(allocator: std.mem.Allocator, text: []const u8) !Self {
    if (!initialized) {
        initialized = true;
        face = try ft.Library.current.?.newFace("/usr/share/fonts/steam-fonts/arial.ttf", 0);
        font = cairo.ftFontFaceCreateForFTFace(face, 0).?;
        if (cairo.fontFaceSetUserData(font, @ptrCast(&key), face, @ptrCast(&cairo.FT_Done_Face)) != 0) {
            cairo.fontFaceDestroy(font);
            _ = cairo.FT_Done_Face(face);
            return Err.FAILED_TO_CREATE_FACE;
        }
    }

    const glyph_indices = try allocator.alloc(u32, text.len);
    defer allocator.free(glyph_indices);
    const kerning = try allocator.alloc(ui.Position(f64), text.len);
    defer allocator.free(kerning);

    for (text, 0..) |char, i| {
        glyph_indices[i] = ft.Library.getGlyphIndex(face, @intCast(char));
    }

    var x:f64 = undefined;
    {
        const bounds = ft.Library.getCBox(face, glyph_indices[0]);
        kerning[0] = .{ .x = 0, .y = 0};
        x = @as(f64, @floatFromInt(bounds.x_max))/64.0;
    }
    for (glyph_indices[1..], 0..) |glyph, i| {
        const left = glyph_indices[i];
        
        const bounds = ft.Library.getCBox(face, glyph);
        const kern = try ft.Library.getKerning(face, left, glyph, ft.KerningMode.DEFAULT);

        kerning[i+1] = .{
            .x = x + @as(f64, @floatFromInt(kern.x))/26.6,
            .y = @as(f64, @floatFromInt(kern.y))/26.6 +
                @as(f64, @floatFromInt(bounds.y_max - bounds.y_min))/64,
        };
        x += kerning[i+1].x + @as(f64, @floatFromInt(bounds.x_max - bounds.x_min))/64;
    }
    const glyphs = try allocator.alloc(ft.Glyph, text.len);
    for (glyph_indices, 0..) |glyph, i| {
        glyphs[i] = .{
            .x = kerning[i].x,
            .y = kerning[i].y,
            .index = glyph,
        };
    }

    for(kerning) |k| {
        std.debug.print("{any}\n", .{k});
    }

    return Self{
        .text = text,
        .glyphs = glyphs,
        .allocator = allocator,
    };
}

pub fn getComponent(self: *Self, allocator: std.mem.Allocator, parent: ?*Component) !Component {
    if (self.component == null) {
        self.component = Component{
            .context = @ptrCast(self),
            .parent = parent,
            .children = std.ArrayList(*Component).init(allocator),
            .update = update,
            .sync = sync,
            .remove = _remove,
        };
        if (parent) |p| {
            try p.addChild(&self.component.?);
        }
    }

    return self.component.?;
}

pub fn update(component: *Component) anyerror!void {
    const self: *const Self = @alignCast(@ptrCast(component.context));
    if (component.invalid) {
        std.debug.print("[Text]: {s}\n", .{self.text});
    }
}

pub fn sync(component: *Component, graphics: *Graphics) anyerror!void {
    const self: *const Self = @alignCast(@ptrCast(component.context));
    if (!component.invalid) return;
    component.invalid = false;


    const pos: ui.Position(f32) = component.pos;
    const size: ui.Size(f32) = component.size orelse .{ .width = 100, .height = 20 };

    const transformed_glyphs = try self.allocator.alloc(ft.Glyph, self.glyphs.len);
    defer self.allocator.free(transformed_glyphs);

    for (transformed_glyphs, 0..) |*glyph, i| {
        glyph.x = self.glyphs[i].x + pos.x;
        glyph.y = self.glyphs[i].y + pos.y;
        glyph.index = self.glyphs[i].index;
    }


    graphics.setSourceRGB(1, 1, 1);
    graphics.rectangle(pos.x, pos.y, size.width, size.height);
    graphics.fill();

    graphics.setFontFace(@alignCast(@ptrCast(font)));
    graphics.setSourceRGB(1, 0, 0);
    try graphics.showGlyphs(transformed_glyphs);
    graphics.fill();
}

pub fn destroy(self: *Self) void {
    if(self.component) |*component| {
        component.destroy();
    } else {
        self.allocator.free(self.glyphs);
    }
}

fn _remove(component: *Component) anyerror!void {
    const _self: *const Self = @alignCast(@ptrCast(component.context));
    const self: *Self = @constCast(_self);
    self.component = null;
    self.allocator.free(self.glyphs);
}

const std = @import("std");
const ui = @import("ui.zig");
const ft = @import("../ft.zig");
const cairo = @import("cairo");
const Component = ui.Component;
const Graphics = @import("../context.zig").Graphics;
const Self = @This();

const Err = error{
    FAILED_TO_CREATE_FACE,
};
