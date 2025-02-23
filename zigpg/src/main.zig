const std = @import("std");
const pg = @import("pg");
const httpz = @import("httpz");

const App = struct {
    pool: *pg.Pool,
    allocator: std.mem.Allocator,
};

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

    var app = App{
        .pool = pool,
        .allocator = allocator,
    };

    var server = try httpz.ServerApp(*App).init(allocator, .{ .port = 3000 }, &app);
    defer {
        // clean shutdown, finishes serving any live request
        server.stop();
        server.deinit();
    }

    var router = server.router();
    router.get("/users", getUsers);
    router.get("/users/:id", getUser);
    router.post("/users", saveUser);
    router.delete("/users/:id", deleteUser);
    // blocks
    try server.listen();
}

const User = struct {
    id: i32,
    name: []const u8,
};

const NewUserReq = struct {
    name: []const u8,
};

pub fn getUsers(app: *App, _: *httpz.Request, res: *httpz.Response) !void {
    var result = try app.pool.query("select id, name from users", .{});
    defer result.deinit();

    var users = std.ArrayList(User).init(app.allocator);
    while (try result.next()) |row| {
        const id = row.get(i32, 0);
        const name = row.get([]u8, 1);
        try users.append(User{ .id = id, .name = name });
    }

    const usersSlice = try users.toOwnedSlice();
    defer app.allocator.free(usersSlice);
    try res.json(usersSlice, .{});
}

pub fn saveUser(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    if (try req.json(NewUserReq)) |body| {
        _ = app.pool.exec("insert into users (name) values ($1)", .{body.name}) catch {
            res.status = 500;
            return;
        };
    }
}

pub fn getUser(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    const userId = req.param("id").?;
    const result = try app.pool.row("select id, name from users where id = $1", .{userId});
    if (result) |r| {
        const user = User{
            .id = r.get(i32, 0),
            .name = r.get([]const u8, 1),
        };

        try res.json(user, .{});
    } else {
        res.status = 404;
    }
    return;
}

pub fn deleteUser(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    const userId = req.param("id").?;
    _ = app.pool.exec("delete from users where id = $1", .{userId}) catch {
        res.status = 500;
        return;
    };
    res.status = 204;
}
