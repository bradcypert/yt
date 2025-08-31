const std = @import("std");

fn divide(a: i32, b: i32) i32 {
    return @divTrunc(a, b);
}

fn calculate(values: []const i32) i32 {
    var result: i32 = 0;
    for (values) |value| {
        result += value;
    }

    for (values, 1..) |_, index| {
        result = divide(result, @intCast(index));
    }

    return result;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const numbers = [_]i32{ 10, 20, 30, 40 };
    const result = calculate(&numbers);

    try stdout.print("Result: {}\n", .{result});
}
