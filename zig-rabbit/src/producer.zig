const std = @import("std");
const amqp = @import("amqp");
const print = std.debug.print;

var rx_memory: [8192]u8 = undefined;
var tx_memory: [8192]u8 = undefined;

const rabbitmq_host: []const u8 = "127.0.0.1";
const rabbitmq_port: u16 = 5672;
const queue_name: []const u8 = "zig_tutorial_queue";
const interval_seconds: u64 = 2;

const Message = struct {
    id: u64,
    timestamp: i64,
    content: []const u8,
    source: []const u8 = "zig-producer",
};

pub fn main() !void {
    print("RabbitMQ: {s}:{d}", .{ rabbitmq_host, rabbitmq_port });
    print("Queue: {s}", .{queue_name});

    var message_count: u64 = 0;

    var conn = amqp.init(&rx_memory, &tx_memory);
    const addr = try std.net.Address.parseIp4(rabbitmq_host, rabbitmq_port);
    conn.connect(addr) catch |err| {
        print("Connection failed: {any}.", .{err});
        return err;
    };

    var ch = try conn.channel();

    _ = try ch.queueDeclare(queue_name, .{ .durable = true }, null);

    while (true) {
        message_count += 1;
        const message = Message{
            .id = message_count,
            .timestamp = std.time.timestamp(),
            .content = "Hello from Zig AMQP Producer!",
        };

        var json_buffer: [1024]u8 = undefined;
        var stream = std.io.fixedBufferStream(&json_buffer);
        std.json.stringify(message, .{}, stream.writer()) catch |err| {
            print("JSON Serialization failed: {any}\n", .{err});
            continue;
        };

        const json_message = stream.getWritten();
        ch.basicPublish("", queue_name, json_message, .{}) catch {
            continue;
        };

        print("Sent message #{d}: {s}\n", .{ message_count, json_message });
        std.time.sleep(std.time.ns_per_s * interval_seconds);
    }
}
