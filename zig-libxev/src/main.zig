const std = @import("std");
const xev = @import("xev");

const TimerData = struct {
    message: []const u8,
    id: u32,
    strategy: xev.CallbackAction,
};

const StopData = struct {};

fn timerCallback(
    userdata: ?*TimerData,
    _: *xev.Loop,
    _: *xev.Completion,
    _: xev.Timer.RunError!void,
) xev.CallbackAction {
    if (userdata) |data| {
        std.debug.print("Timer {d} : {s}\n", .{ data.id, data.message });
        return data.strategy;
    }

    return .disarm;
}

fn stopCallback(
    _: ?*StopData,
    loop: *xev.Loop,
    _: *xev.Completion,
    _: xev.Timer.RunError!void,
) xev.CallbackAction {
    loop.stop();
    std.debug.print("Poison Pill acquired\n", .{});
    return .disarm;
}

pub fn main() !void {
    var debugAllocator = std.heap.DebugAllocator(.{}){};
    defer _ = debugAllocator.deinit();

    var loop = try xev.Loop.init(.{});
    defer loop.deinit();

    std.debug.print("Starting libxev async example...\n", .{});

    const timer1 = try xev.Timer.init();
    defer timer1.deinit();
    var timer_data = TimerData{
        .message = "Timer 1 fired",
        .id = 1,
        .strategy = .disarm,
    };

    var c1: xev.Completion = undefined;
    timer1.run(&loop, &c1, 3000, TimerData, &timer_data, timerCallback);

    const timer2 = try xev.Timer.init();
    defer timer2.deinit();
    var timer_data2 = TimerData{
        .message = "Timer 2 fired",
        .id = 2,
        .strategy = .disarm,
    };

    var c2: xev.Completion = undefined;
    timer2.run(&loop, &c2, 1000, TimerData, &timer_data2, timerCallback);

    const timer3 = try xev.Timer.init();
    defer timer3.deinit();

    var c3: xev.Completion = undefined;
    timer3.run(&loop, &c3, 1500, StopData, null, stopCallback);

    try loop.run(.until_done);

    std.debug.print("Event loop finished\n", .{});
}
