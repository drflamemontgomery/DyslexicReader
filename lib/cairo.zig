const _cairo = @cImport({@cInclude("cairo/cairo.h");});

pub const Surface = _cairo.cairo_surface_t;
pub const Context = _cairo.cairo_t;

pub const create = _cairo.cairo_create;
pub const destroy = _cairo.cairo_destroy;
pub const imageSurfaceCreateForData = _cairo.cairo_image_surface_create_for_data;
pub const setSourceRGB = _cairo.cairo_set_source_rgb;
pub const rectangle = _cairo.cairo_rectangle;
pub const fill = _cairo.cairo_fill;

pub const FORMAT_ARGB32 = _cairo.CAIRO_FORMAT_ARGB32;
