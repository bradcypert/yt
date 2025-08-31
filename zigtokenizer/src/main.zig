const std = @import("std");

const TokenType = enum {
    Number,
    Plus,
    Minus,
    Multiply,
    Divide,
    Invalid,
};

const Token = struct {
    typ: TokenType,
    value: []const u8,
};

fn tokenize(allocator: std.mem.Allocator, input: []const u8) error{OutOfMemory}![]Token {
    var tokens = std.ArrayList(Token).init(allocator);
    var i: usize = 0;
    sw: switch (input[i]) {
        '0'...'9' => {
            const start: usize = i;
            while (i < input.len and input[i] >= '0' and input[i] <= '9') {
                i += 1;
            }
            try tokens.append(Token{ .typ = .Number, .value = input[start..i] });
            continue :sw input[i];
        },
        '\n' => {
            break :sw;
        },
        '+' => {
            try tokens.append(Token{ .typ = .Plus, .value = input[i .. i + 1] });
            i += 1;
            continue :sw input[i];
        },
        '-' => {
            try tokens.append(Token{ .typ = .Minus, .value = input[i .. i + 1] });
            i += 1;
            continue :sw input[i];
        },
        '*' => {
            try tokens.append(Token{ .typ = .Multiply, .value = input[i .. i + 1] });
            i += 1;
            continue :sw input[i];
        },
        '/' => {
            try tokens.append(Token{ .typ = .Divide, .value = input[i .. i + 1] });
            i += 1;
            continue :sw input[i];
        },
        ' ' => {
            i += 1;
            continue :sw input[i];
        },
        else => {
            try tokens.append(Token{ .typ = .Invalid, .value = input[i .. i + 1] });
            i += 1;
            continue :sw input[i];
        },
    }

    return tokens.toOwnedSlice();
}

test "tokenize" {
    const input = "88 + 92 - 31 * 755 /2\n";
    const tokens = try tokenize(std.testing.allocator, input);
    defer std.testing.allocator.free(tokens);
    for (tokens) |token| {
        std.debug.print("Token: {s}\n", .{token.value});
    }
}
