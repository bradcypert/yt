const std = @import("std");
const zap = @import("zap");
const pg = @import("pg");

const User = struct {
    id: i32,
    name: []const u8,
};

const NewUserReq = struct {
    name: []const u8,
};

pub const UserController = struct {
    pool: *pg.Pool,
    allocator: std.mem.Allocator,
    ep: zap.Endpoint = undefined,

    pub fn init(allocator: std.mem.Allocator, pool: *pg.Pool) UserController {
        return UserController{
            .pool = pool,
            .allocator = allocator,
            .ep = zap.Endpoint.init(.{
                .path = "/users",
                .get = UserController.dispatch,
                .post = UserController.saveUser,
                .delete = UserController.deleteUser,
            }),
        };
    }

    pub fn endpoint(self: *UserController) *zap.Endpoint {
        return &self.ep;
    }

    pub fn dispatch(e: *zap.Endpoint, req: zap.Request) void {
        if (req.path) |path| {
            if (UserController.userIdFromPath(path)) |_| {
                UserController.getUser(e, req) catch req.setStatus(.internal_server_error);
            } else {
                UserController.getUsers(e, req) catch req.setStatus(.internal_server_error);
            }
        } else {
            req.setStatus(.not_found);
            req.sendBody("") catch return;
        }
    }

    fn userIdFromPath(path: []const u8) ?usize {
        if (path.len >= "/users".len + 2) {
            if (path["/users".len] != '/') {
                return null;
            }
            const idstr = path["/users".len + 1 ..];
            return std.fmt.parseUnsigned(usize, idstr, 10) catch null;
        }
        return null;
    }

    pub fn getUsers(e: *zap.Endpoint, req: zap.Request) !void {
        const self: *UserController = @fieldParentPtr("ep", e);

        if (req.path) |_| {
            var result = try self.pool.query("select id, name from users", .{});
            defer result.deinit();

            var users = std.ArrayList(User).init(self.allocator);
            while (try result.next()) |row| {
                const id = row.get(i32, 0);
                const name = row.get([]u8, 1);
                try users.append(User{ .id = id, .name = name });
            }

            var string = std.ArrayList(u8).init(self.allocator);
            const usersSlice = try users.toOwnedSlice();
            defer self.allocator.free(usersSlice);
            try std.json.stringify(usersSlice, .{}, string.writer());
            const s = try string.toOwnedSlice();
            defer self.allocator.free(s);

            req.sendBody(s) catch return;
        }
    }

    pub fn saveUser(e: *zap.Endpoint, req: zap.Request) void {
        const self: *UserController = @fieldParentPtr("ep", e);

        if (req.body) |body| {
            const maybe_user: ?std.json.Parsed(NewUserReq) = std.json.parseFromSlice(NewUserReq, self.allocator, body, .{}) catch |err| {
                std.debug.print("error parsing json: {any}\n", .{err});
                req.setStatus(.bad_request);
                return;
            };
            if (maybe_user) |user| {
                defer user.deinit();
                _ = self.pool.exec("insert into users (name) values ($1)", .{user.value.name}) catch {
                    req.setStatus(.internal_server_error);
                    return;
                };
            }
        }
    }

    pub fn getUser(e: *zap.Endpoint, req: zap.Request) !void {
        const self: *UserController = @fieldParentPtr("ep", e);

        if (req.path) |path| {
            if (UserController.userIdFromPath(path)) |userId| {
                const result = try self.pool.row("select id, name from users where id = $1", .{userId});
                if (result) |r| {
                    const user = User{
                        .id = r.get(i32, 0),
                        .name = r.get([]const u8, 1),
                    };

                    var string = std.ArrayList(u8).init(self.allocator);
                    try std.json.stringify(user, .{}, string.writer());
                    const s = try string.toOwnedSlice();
                    defer self.allocator.free(s);
                    req.sendBody(s) catch return;
                } else {
                    req.setStatus(.not_found);
                }
                return;
            }

            req.setStatus(.not_found);
        }
    }

    pub fn deleteUser(e: *zap.Endpoint, req: zap.Request) void {
        const self: *UserController = @fieldParentPtr("ep", e);

        if (req.path) |path| {
            if (UserController.userIdFromPath(path)) |userId| {
                _ = self.pool.exec("delete from users where id = $1", .{userId}) catch {
                    req.setStatus(.internal_server_error);
                    return;
                };
                req.setStatus(.ok);
            }
        }
    }
};
