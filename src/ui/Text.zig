var initialized: bool = false;
var face: cairo.FT_Face = undefined;
var scaled_font: ScaledFont = undefined;
var key: cairo.UserDataKey = undefined;

allocator: std.mem.Allocator,
text: []const u8,
glyphs: []cairo.Glyph,
component: ?Component = null,

pub fn new(allocator: std.mem.Allocator, text: []const u8) !Self {
    if (!initialized) {
        initialized = true;
        scaled_font = try ScaledFont.get(12, "/usr/share/fonts/steam-fonts/arial.ttf");
    }

    var glyphs: []cairo.Glyph = try allocator.alloc(cairo.Glyph, text.len);
    errdefer allocator.free(glyphs);

    const glyph_len = try scaled_font.textToGlyphs(0, 0, text, glyphs);
    if(glyph_len != glyphs.len) {
        glyphs = try allocator.realloc(glyphs, glyph_len);
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

    graphics.setSourceRGB(1, 1, 1);
    graphics.rectangle(pos.x, pos.y, size.width, size.height);
    graphics.fill();

    graphics.setScaledFont(scaled_font);
    graphics.setSourceRGB(1, 0, 0);
    graphics.showGlyphsAt(pos.x, pos.y+size.height, self.glyphs);
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
const ScaledFont = @import("../context.zig").ScaledFont;
const Self = @This();

const Err = error{
    FAILED_TO_CREATE_FACE,
};
