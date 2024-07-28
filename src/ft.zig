const freetype = @import("abi").freetype;
const ui = @import("ui/ui.zig");

/// A wrapper structure for dealing with the freetype libraries
pub const Library = struct {
    pub var current: ?Library = null;
    library: freetype.FT_Library,

    pub fn init() !Self {
        var library: freetype.FT_Library = undefined;
        if (freetype.FT_Init_FreeType(@ptrCast(&library)) != 0) {
            return Err.FAILED_TO_INIT_FREETYPE;
        }
        current = .{
            .library = library,
        };

        return current.?;
    }

    pub fn newFace(self: Self, path: []const u8, face_index: i64) !Face {
        var face: freetype.FT_Face = undefined;
        if (freetype.FT_New_Face(self.library, @ptrCast(path), face_index, @ptrCast(&face)) != 0) {
            return Err.FAILED_TO_CREATE_NEW_FACE;
        }
        return face;
    }

    pub fn destroy(self: Self) !void {
        if (freetype.FT_Done_FreeType(self.library) != 0) {
            return Err.FAILED_TO_DESTROY_FREETYPE;
        }
    }

    pub fn getGlyphIndex(face: Face, code: u64) u32 {
        return @intCast(freetype.FT_Get_Char_Index(face, code));
    }

    pub fn getCBox(face: Face, glyph_index: u32) Box {
        var glyph: freetype.FT_Glyph = undefined;
        _ = freetype.loadGlyph(face, glyph_index, freetype.FT_LOAD_DEFAULT);
        _ = freetype.FT_Get_Glyph(face[0].glyph, &glyph);
        defer freetype.FT_Done_Glyph(glyph);

        var box: freetype.FT_BBox = undefined;
        freetype.FT_Glyph_Get_CBox(glyph, freetype.FT_GLYPH_BBOX_UNSCALED, &box);

        return Box.fromFT_BBox(box);
    }

    pub fn getKerning(face: Face, left_glyph: u32, right_glyph: u32, kern_mode: KerningMode) !ui.Position(i64) {
        var vec: freetype.FT_Vector = undefined;
        if (freetype.FT_Get_Kerning(face, @intCast(left_glyph), @intCast(right_glyph), @intFromEnum(kern_mode), @ptrCast(&vec)) != 0) {
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

    pub fn fromFT_BBox(box: freetype.FT_BBox) Box {
        return .{
            .x_min = box.xMin,
            .y_min = box.yMin,
            .x_max = box.xMax,
            .y_max = box.yMax,
        };
    }
};

pub const Face = freetype.FT_Face;
pub const KerningMode = freetype.FT_Kerning_Mode;
