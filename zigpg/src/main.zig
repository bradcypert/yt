const std = @import("std");
const zap = @import("zap");
const pg = @import("pg");
const usersController = @import("./users_controller.zig");

fn not_found(req: zap.Request) void {
    req.setStatus(.not_found);
    req.sendBody("Not found") catch return;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    const allocator = gpa.allocator();

    var pool = try pg.Pool.init(allocator, .{ .size = 5, .connect = .{
        .port = 5432,
        .host = "127.0.0.1",
    }, .auth = .{
        .username = "zap_user",
        .database = "zap_db",
        .password = "abc123",
        .timeout = 10_000,
    } });
    defer pool.deinit();

    _ = try pool.exec("create table if not exists users (id serial primary key, name text)", .{});

    var simpleRouter = zap.Router.init(allocator, .{
        .not_found = not_found,
    });
    defer simpleRouter.deinit();

    var userController = usersController.UserController.init(allocator, pool);

    var listener = zap.Endpoint.Listener.init(allocator, .{
        .port = 3000,
        .on_request = simpleRouter.on_request_handler(),
        .log = true,
    });
    defer listener.deinit();

    try listener.register(userController.endpoint());

    try listener.listen();

    std.debug.print("Listening on 0.0.0.0:3000\n", .{});

    // start worker threads
    zap.start(.{
        .threads = 1,
        .workers = 1,
    });
}
