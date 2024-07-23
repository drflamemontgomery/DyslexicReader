const cairo = @import("cairo");
const ui = @import("ui/ui.zig");

pub const Face = cairo.FT_Face;
pub const KerningMode = cairo.FT_Kerning_Mode;

pub const Glyph = struct {
    index: u64,
    x: f64,
    y: f64,
};

pub const Box = struct {
    x_min: i64,
    y_min: i64,
    x_max: i64,
    y_max: i64,

    pub fn fromFT_BBox(box:cairo.FT_BBox) Box {
        return .{
            .x_min = box.xMin,
            .y_min = box.yMin,
            .x_max = box.xMax,
            .y_max = box.yMax,
        };
    }
};

pub const Library = struct {
    pub var current: ?Library = null;
    library: cairo.FT_Library,

    pub fn init() !Self {
        var library: cairo.FT_Library = undefined;
        if (cairo.FT_Init_FreeType(@ptrCast(&library)) != 0) {
            return Err.FAILED_TO_INIT_FREETYPE;
        }
        current = .{
            .library = library,
        };

        return current.?;
    }

    pub fn newFace(self: Self, path: []const u8, face_index: i64) !Face {
        var face: cairo.FT_Face = undefined;
        if (cairo.FT_New_Face(self.library, @ptrCast(path), face_index, @ptrCast(&face)) != 0) {
            return Err.FAILED_TO_CREATE_NEW_FACE;
        }
        return face;
    }

    pub fn destroy(self: Self) !void {
        if (cairo.FT_Done_FreeType(self.library) != 0) {
            return Err.FAILED_TO_DESTROY_FREETYPE;
        }
    }

    pub fn getGlyphIndex(face: Face, code: u64) u32 {
        return @intCast(cairo.FT_Get_Char_Index(face, code));
    }

    pub fn getCBox(face: Face, glyph_index: u32) Box {
        var glyph: cairo.FT_Glyph = undefined;
        _ = cairo.loadGlyph(face, glyph_index, cairo.FT_LOAD_DEFAULT);
        _ = cairo.FT_Get_Glyph(face[0].glyph, &glyph);
        defer cairo.FT_Done_Glyph(glyph);

        var box:cairo.FT_BBox = undefined;
        cairo.FT_Glyph_Get_CBox(glyph, cairo.FT_GLYPH_BBOX_UNSCALED, &box); 

        return Box.fromFT_BBox(box);
    }

    pub fn getKerning(face: Face, left_glyph: u32, right_glyph: u32, kern_mode: KerningMode) !ui.Position(i64) {
        var vec: cairo.FT_Vector = undefined;
        if(cairo.FT_Get_Kerning(face, @intCast(left_glyph), @intCast(right_glyph), @intFromEnum(kern_mode), @ptrCast(&vec)) != 0) {
            return Err.KERNING_ERROR;
        }
        return .{
            .x = @intCast(vec.x),
            .y = @intCast(vec.y),
        };
    }

    const Self = @This();
    const Err = error{
        FAILED_TO_INIT_FREETYPE,
        FAILED_TO_DESTROY_FREETYPE,
        FAILED_TO_CREATE_NEW_FACE,
        KERNING_ERROR,
    };
};
