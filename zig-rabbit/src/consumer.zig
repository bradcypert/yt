const std = @import("std");
const amqp = @import("amqp");
const print = std.debug.print;

var rx_memory: [8192]u8 = undefined;
var tx_memory: [8192]u8 = undefined;
const rabbitmq_host: []const u8 = "127.0.0.1";
const rabbitmq_port: u16 = 5672;
const queue_name: []const u8 = "zig_tutorial_queue";

const ReceivedMessage = struct {
    id: u64,
    timestamp: i64,
    content: []const u8,
    source: []const u8,
};

fn processMessage(allocator: std.mem.Allocator, message_body: []const u8) !void {
    const parsed = std.json.parseFromSlice(ReceivedMessage, allocator, message_body, .{}) catch |err| {
        print("Failed to parse message JSON: {any}\n", .{err});
        print("Raw message: {s}\n", .{message_body});
        return;
    };

    defer parsed.deinit();

    const message = parsed.value;
    const current_time = std.time.timestamp();
    const message_age = current_time - message.timestamp;

    print("Received message #{d} from {s}\n", .{ message.id, message.source });
    print("  Content: {s}\n", .{message.content});
    print("  Age: {d} seconds\n", .{message_age});
    print("  Processed at: {d}\n\n", .{current_time});
}

pub fn main() !void {
    var debugAllocator = std.heap.DebugAllocator(.{}){};
    defer _ = debugAllocator.deinit();
    const allocator = debugAllocator.allocator();

    print("RabbitMQ: {s}:{d}\n", .{ rabbitmq_host, rabbitmq_port });
    print("Queue: {s}\n", .{queue_name});

    var conn = amqp.init(&rx_memory, &tx_memory);
    const addr = try std.net.Address.parseIp4(rabbitmq_host, rabbitmq_port);
    try conn.connect(addr);
    var ch = try conn.channel();
    _ = try ch.queueDeclare(queue_name, .{ .durable = true }, null);

    print("Connected to queue: {s}. Waiting for messages...\n", .{queue_name});

    var consumer = try ch.basicConsume(queue_name, .{ .no_ack = true }, null);
    while (true) {
        const message = try consumer.next();

        processMessage(allocator, message.body) catch |err| {
            print("Message processing failed: {any}\n", .{err});
        };
    }
}
