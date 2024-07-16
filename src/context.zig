const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");

var _internal_texture_id: c_uint = 0;
var gl_procs: gl.ProcTable = undefined;

pub const Context = struct {
    const Err = error{
        FAILED_TO_INITIALIZE_GLFW,
        FAILED_TO_CREATE_WINDOW,
        FAILED_TO_INITIALIZE_OPENGL,
    };
    const Self = @This();
    var current: ?*Self = null;

    pub const pollEvents = glfw.pollEvents;

    window: *glfw.Window,
    graphics: Graphics,

    pub fn init() Err!void {
        if (glfw.init() == 0) return Err.FAILED_TO_INITIALIZE_GLFW;
    }

    pub fn new(allocator: std.mem.Allocator, title: []const u8, width: i32, height: i32) !Self {
        glfw.windowHint(glfw.RESIZABLE, glfw.TRUE);
        glfw.windowHint(glfw.AUTO_ICONIFY, glfw.TRUE);
        glfw.windowHint(glfw.SAMPLES, 4);
        glfw.windowHint(glfw.CONTEXT_VERSION_MAJOR, 2);
        glfw.windowHint(glfw.CONTEXT_VERSION_MINOR, 0);
        glfw.windowHint(glfw.DECORATED, glfw.FALSE);

        _ = glfw.setErrorCallback(onGlfwError);

        const window: *glfw.Window = glfw.createWindow(width, height, &title[0], null, null) orelse return Err.FAILED_TO_CREATE_WINDOW;
        errdefer glfw.destroyWindow(window);

        glfw.makeContextCurrent(window);
        glfw.setInputMode(window, glfw.STICKY_KEYS, gl.TRUE);

        _ = glfw.setFramebufferSizeCallback(window, onResize);

        if (!gl_procs.init(glfw.getProcAddress)) return error.FAILED_TO_INITIALIZE_OPENGL;
        gl.makeProcTableCurrent(&gl_procs);

        gl.Disable(gl.DEPTH_TEST);
        gl.Enable(gl.BLEND);
        gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
        gl.Enable(gl.TEXTURE_RECTANGLE_ARB);

        const graphics = try Graphics.new(try ImageSurface.new(allocator, width, height));
        const self = Self{
            .window = window,
            .graphics = graphics,
        };

        return self;
    }

    pub fn makeCurrent(self: ?*Self) void {
        current = self;
    }

    pub fn resize(self: *Self, width: i32, height: i32) !void {
        gl.Viewport(0, 0, width, height);
        gl.MatrixMode(gl.PROJECTION);
        gl.LoadIdentity();
        gl.Ortho(0.0, 1.0, 0.0, 1.0, -1.0, 1.0);

        gl.Clear(gl.COLOR_BUFFER_BIT);

        gl.DeleteTextures(1, @ptrCast(&_internal_texture_id));
        gl.GenTextures(1, @ptrCast(&_internal_texture_id));
        gl.BindTexture(gl.TEXTURE_RECTANGLE_ARB, _internal_texture_id);
        gl.TexImage2D(gl.TEXTURE_RECTANGLE_ARB, 0, gl.RGBA, width, height, 0, gl.BGRA, gl.UNSIGNED_BYTE, null);
        gl.TexEnvi(gl.TEXTURE_ENV, gl.TEXTURE_ENV_MODE, gl.DECAL);

        try self.graphics.resize(width, height);
    }

    pub fn render(self: Self) void {
        gl.MatrixMode(gl.MODELVIEW);
        gl.LoadIdentity();
        gl.Clear(gl.COLOR_BUFFER_BIT);

        gl.PushMatrix();

        gl.BindTexture(gl.TEXTURE_RECTANGLE_ARB, _internal_texture_id);
        gl.TexImage2D(gl.TEXTURE_RECTANGLE_ARB, 0, gl.RGBA, self.graphics.surface.width, self.graphics.surface.height, 0, gl.BGRA, gl.UNSIGNED_BYTE, @ptrCast(&self.graphics.surface.data[0]));

        gl.Color3f(0, 1, 0);
        gl.Begin(gl.QUADS);

        gl.TexCoord2f(0, @floatFromInt(self.graphics.surface.height));
        gl.Vertex2f(0, 0);

        gl.TexCoord2f(@floatFromInt(self.graphics.surface.width), @floatFromInt(self.graphics.surface.height));
        gl.Vertex2f(1, 0);

        gl.TexCoord2f(@floatFromInt(self.graphics.surface.width), 0);
        gl.Vertex2f(1, 1);

        gl.TexCoord2f(0, 0);
        gl.Vertex2f(0, 1);

        gl.End();

        gl.PopMatrix();
    }

    pub fn swapBuffers(self: Self) void {
        glfw.swapBuffers(self.window);
    }

    pub fn shouldClose(self: Self) bool {
        return glfw.windowShouldClose(self.window) != 0;
    }

    pub fn destroy(self: Self) void {
        glfw.destroyWindow(self.window);
    }

    pub fn terminate() void {
        glfw.terminate();
    }

    fn onResize(win: ?*glfw.Window, width: c_int, height: c_int) callconv(.C) void {
        _ = win;
        if (current == null) return;
        current.?.resize(width, height) catch |err| {
            std.debug.print("error: {}", .{err});
        };
    }
};

const cairo = @import("cairo.zig");

pub const ImageSurface = struct {
    const Self = @This();
    const Err = error{
        FAILED_TO_CREATE_SURFACE,
    };

    allocator: std.mem.Allocator,
    surface: *cairo.Surface,
    data: []u32,
    width: i32,
    height: i32,

    pub fn new(allocator: std.mem.Allocator, width: i32, height: i32) !Self {
        const data = try allocator.alloc(u32, @intCast(width * height));
        errdefer allocator.free(data);

        const surface = cairo.imageSurfaceCreateForData(@ptrCast(&data[0]), cairo.FORMAT_ARGB32, width, height, 4 * width) orelse return Err.FAILED_TO_CREATE_SURFACE;
        return Self{
            .allocator = allocator,
            .surface = surface,
            .data = data,
            .width = width,
            .height = height,
        };
    }

    pub fn resize(self: *Self, width: i32, height: i32) !void {
        self.width = width;
        self.height = height;
        self.destroy();

        self.data = try self.allocator.alloc(u32, @intCast(width * height));
        errdefer self.allocator.free(self.data);

        self.surface = cairo.imageSurfaceCreateForData(@ptrCast(&self.data[0]), cairo.FORMAT_ARGB32, width, height, 4 * width) orelse return Err.FAILED_TO_CREATE_SURFACE;
    }

    pub fn destroy(self: Self) void {
        // data is allocated by the cairo library using malloc
        std.c.free(self.surface);
        self.allocator.free(self.data);
    }
};

pub const Graphics = struct {
    const Self = @This();
    const Err = error{
        FAILED_TO_CREATE_CAIRO_CONTEXT,
        FAILED_TO_RESIZE_SURFACE,
    };

    ctx: *cairo.Context,
    surface: ImageSurface,

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

    pub fn new(surface: ImageSurface) Err!Self {
        const ctx = cairo.create(surface.surface) orelse return Err.FAILED_TO_CREATE_CAIRO_CONTEXT;
        return Self{
            .surface = surface,
            .ctx = ctx,
        };
    }

    pub fn resize(self: *Self, width: i32, height: i32) Err!void {
        cairo.destroy(self.ctx);
        self.surface.resize(width, height) catch return Err.FAILED_TO_RESIZE_SURFACE;
        self.ctx = cairo.create(self.surface.surface) orelse return Err.FAILED_TO_CREATE_CAIRO_CONTEXT;
    }

    pub fn destroy(self: Self) void {
        cairo.destroy(self.ctx);
        cairo.surface.destroy();
    }
};

fn onGlfwError(code: c_int, message: [*c]const u8) callconv(.C) void {
    _ = code;
    std.debug.print("{s}\n", .{message});
}
