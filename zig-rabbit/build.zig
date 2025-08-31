const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const amqp_dep = b.dependency("amqp", .{
        .target = target,
        .optimize = optimize,
    });

    const producer_exe = b.addExecutable(.{
        .name = "producer",
        .root_source_file = b.path("src/producer.zig"),
        .target = target,
        .optimize = optimize,
    });

    producer_exe.root_module.addImport("amqp", amqp_dep.module("amqp"));

    const consumer_exe = b.addExecutable(.{
        .name = "consumer",
        .root_source_file = b.path("src/consumer.zig"),
        .target = target,
        .optimize = optimize,
    });

    consumer_exe.root_module.addImport("amqp", amqp_dep.module("amqp"));

    b.installArtifact(producer_exe);
    b.installArtifact(consumer_exe);

    const run_producer = b.addRunArtifact(producer_exe);
    const run_consumer = b.addRunArtifact(consumer_exe);

    if (b.args) |args| {
        run_producer.addArgs(args);
        run_consumer.addArgs(args);
    }

    const run_producer_step = b.step("run-producer", "Run the producer");
    run_producer_step.dependOn(&run_producer.step);

    const run_consumer_step = b.step("run-consumer", "Run the consumer");
    run_consumer_step.dependOn(&run_consumer.step);
}
