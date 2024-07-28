const abi = @import("c_abi.zig");

pub const FT_Face = abi.FT_Face;
pub const FT_Vector = abi.FT_Vector;
pub const FT_Kerning_Mode = abi.FT_Kerning_Mode;
pub const FT_Glyph = abi.FT_Glyph;
pub const FT_BBox = abi.FT_BBox;

pub const FT_Library = abi.FT_Library;
pub const FT_Init_FreeType = abi.FT_Init_FreeType;
pub const FT_Done_Face = abi.FT_Done_Face;
pub const FT_New_Face = abi.FT_New_Face;
pub const FT_Done_Glyph = abi.FT_Done_Glyph;
pub const FT_Get_Char_Index = abi.FT_Get_Char_Index;
pub const FT_Get_Kerning = abi.FT_Get_Kerning;
pub const FT_Get_Glyph = abi.FT_Get_Glyph;
pub const FT_Glyph_Get_CBox = abi.FT_Glyph_Get_CBox;

pub const loadGlyph = abi.FT_Load_Glyph;

pub const FT_LOAD_DEFAULT = abi.FT_LOAD_DEFAULT;
pub const FT_GLYPH_BBOX_UNSCALED = abi.FT_GLYPH_BBOX_UNSCALED;
