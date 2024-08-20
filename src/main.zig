const std = @import("std");
const zigui = @import("zig-ui");
const ui = zigui.ui;
const App = zigui.App;

pub fn main() !void {
    try App.init();
    defer App.deinit();

    var app = try App.create(.{
        .title = "Dyslexic Document Reader",

        .init = init,
        .main_loop = mainLoop,
    });
    defer app.destroy();

    try app.run();
}

var text:ui.Text = undefined;
fn init(app: *App) anyerror!void {
    text = try ui.Text.new(App.arena, "Hello World!", .{});
    text.color = ui.Color.fromHSV(50, 0.79, 0.8);
    _ = try text.getComponent(App.arena, &app.window.ctx.component);
}

fn mainLoop(app: *App) anyerror!void {
    _ = app;
}
