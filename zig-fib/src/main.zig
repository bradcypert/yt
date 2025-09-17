const std = @import("std");

fn fib(n: u32) u64 {
    if (n < 2) return n;
    return fib(n - 1) + fib(n - 2);
}

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    defer stdout.flush() catch {};
    const start = std.time.nanoTimestamp();

    const result = fib(44); // intentionally slow
    try stdout.print("fib(44) = {}\n", .{result});

    const duration = std.time.nanoTimestamp() - start;
    try stdout.print("Took {} ns\n", .{duration});
}
