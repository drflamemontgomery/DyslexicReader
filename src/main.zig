const std = @import("std");
const zigui = @import("zig-ui");
const ui = zigui.ui;

const App = zigui.App(State);
const State = struct {
    text: ui.Text,
};

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

fn init(app: *App) anyerror!void {
    app.state.text = try ui.Text.new(App.arena, "Hello World!", .{});
    app.state.text.color = ui.Color.fromHSV(50, 0.79, 0.8);
    _ = try app.state.text.getComponent(App.arena, &app.window.ctx.component);
}

fn mainLoop(app: *App) anyerror!void {
    _ = app;
}
