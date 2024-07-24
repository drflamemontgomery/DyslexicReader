const _cairo = @import("_cairo.zig");

pub const Surface = _cairo.cairo_surface_t;
pub const Context = _cairo.cairo_t;
pub const FontFace = _cairo.cairo_font_face_t;
pub const UserDataKey = _cairo.cairo_user_data_key_t;
pub const Glyph = _cairo.cairo_glyph_t;
pub const ScaledFont = _cairo.cairo_scaled_font_t;
pub const Matrix = _cairo.cairo_matrix_t;
pub const FontOptions = _cairo.cairo_font_options_t;
pub const TextClusters = _cairo.cairo_text_cluster_t;
pub const TextClusterFlags = _cairo.cairo_text_cluster_flags_t;

pub const create = _cairo.cairo_create;
pub const destroy = _cairo.cairo_destroy;
pub const imageSurfaceCreateForData = _cairo.cairo_image_surface_create_for_data;
pub const setSourceRGB = _cairo.cairo_set_source_rgb;
pub const rectangle = _cairo.cairo_rectangle;
pub const fill = _cairo.cairo_fill;
pub const fontFaceDestroy = _cairo.cairo_font_face_destroy;
pub const setFontFace = _cairo.cairo_set_font_face;
pub const ftFontFaceCreateForFTFace = _cairo.cairo_ft_font_face_create_for_ft_face;
pub const fontFaceSetUserData = _cairo.cairo_font_face_set_user_data;
pub const showGlyphs = _cairo.cairo_show_glyphs;
pub const setScaledFont = _cairo.cairo_set_scaled_font;
pub const scaledFontCreate = _cairo.cairo_scaled_font_create;
pub const scaledFontDestroy = _cairo.cairo_scaled_font_destroy;
pub const scaledFontTextToGlyphs = _cairo.cairo_scaled_font_text_to_glyphs;
pub const fontOptionsCreate = _cairo.cairo_font_options_create;
pub const fontOptionsDestroy = _cairo.cairo_font_options_destroy;
pub const matrixInitScale = _cairo.cairo_matrix_init_scale;
pub const matrixInitIdentity = _cairo.cairo_matrix_init_identity;
pub const matrixInitTranslate = _cairo.cairo_matrix_init_translate;
pub const matrixMultiply = _cairo.cairo_matrix_multiply;
pub const glyphFree = _cairo.cairo_glyph_free;
pub const textClusterFree = _cairo.cairo_text_cluster_free;
pub const getFontMatrix = _cairo.cairo_get_font_matrix;
pub const setFontMatrix = _cairo.cairo_set_font_matrix;

pub const FORMAT_ARGB32 = _cairo.CAIRO_FORMAT_ARGB32;
pub const STATUS_SUCCESS = _cairo.CAIRO_STATUS_SUCCESS;

pub const FT_Face = _cairo.FT_Face;
pub const FT_Vector = _cairo.FT_Vector;
pub const FT_Kerning_Mode = _cairo.FT_Kerning_Mode;
pub const FT_Glyph = _cairo.FT_Glyph;
pub const FT_BBox = _cairo.FT_BBox;

pub const FT_Library = _cairo.FT_Library;
pub const FT_Init_FreeType = _cairo.FT_Init_FreeType;
pub const FT_Done_Face = _cairo.FT_Done_Face;
pub const FT_New_Face = _cairo.FT_New_Face;
pub const FT_Done_Glyph = _cairo.FT_Done_Glyph;
pub const FT_Get_Char_Index = _cairo.FT_Get_Char_Index;
pub const FT_Get_Kerning = _cairo.FT_Get_Kerning;
pub const FT_Get_Glyph = _cairo.FT_Get_Glyph;
pub const FT_Glyph_Get_CBox = _cairo.FT_Glyph_Get_CBox;

pub const loadGlyph = _cairo.FT_Load_Glyph;

pub const FT_LOAD_DEFAULT = _cairo.FT_LOAD_DEFAULT;
pub const FT_GLYPH_BBOX_UNSCALED = _cairo.FT_GLYPH_BBOX_UNSCALED;
