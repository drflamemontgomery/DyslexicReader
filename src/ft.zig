const freetype = @import("abi").freetype;
const ui = @import("ui/ui.zig");

/// A wrapper structure for dealing with the freetype libraries
pub const Library = struct {
    /// The registered Library for the application
    pub var current: ?Library = null;

    /// The Internal freetype library handle
    library: freetype.FT_Library,

    /// Initialize the freetype library
    /// Call this before creating a Library Structure
    /// Call `Library.current.destroy()` to free the resources
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

    /// Load a freetype font from a `path` at index
    pub fn newFace(self: Self, path: []const u8, face_index: i64) !Face {
        var face: freetype.FT_Face = undefined;
        if (freetype.FT_New_Face(self.library, @ptrCast(path), face_index, @ptrCast(&face)) != 0) {
            return Err.FAILED_TO_CREATE_NEW_FACE;
        }
        return face;
    }

    /// Free the freetype library resources
    pub fn destroy(self: Self) !void {
        if (freetype.FT_Done_FreeType(self.library) != 0) {
            return Err.FAILED_TO_DESTROY_FREETYPE;
        }
    }

    /// Get the index of the glyph code in the freetpye font
    pub fn getGlyphIndex(face: Face, code: u64) u32 {
        return @intCast(freetype.FT_Get_Char_Index(face, code));
    }

    const Self = @This();
    const Err = error{
        FAILED_TO_INIT_FREETYPE,
        FAILED_TO_DESTROY_FREETYPE,
        FAILED_TO_CREATE_NEW_FACE,
    };
};

pub const Face = freetype.FT_Face;
