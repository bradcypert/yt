const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const imagemagick_exe = b.addExecutable(.{
        .name = "zig-imagemagick",
        .root_source_file = b.path("./src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    imagemagick_exe.linkSystemLibrary("MagickWand");
    imagemagick_exe.linkSystemLibrary("MagickCore");
    imagemagick_exe.linkLibC();

    b.installArtifact(imagemagick_exe);

    const run_cmd = b.addRunArtifact(imagemagick_exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the code example");
    run_step.dependOn(&run_cmd.step);
}
