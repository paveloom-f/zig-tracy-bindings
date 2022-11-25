const std = @import("std");
const fs = std.fs;

// Build the program
pub fn build(b: *std.build.Builder) void {
    // Define standard target and release options
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();
    // Add the source code of the executable
    const exe = b.addExecutable("example", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();
    // Define the run step
    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    // Add the run step to the builder
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Create an option for the path to Tracy's source code
    const tracy_path_option = b.option(
        []const u8,
        "tracy",
        "Path to Tracy source (enables Tracy integration)",
    );
    const tracy_depth_option = b.option(
        c_int,
        "tracy-depth",
        "Overrides Tracy's default call stack capture depth",
    ) orelse 0;
    // Add these options to a separate group of options
    const tracy_options = b.addOptions();
    exe.addOptions("tracy_options", tracy_options);
    tracy_options.addOption(bool, "tracy", tracy_path_option != null);
    tracy_options.addOption(c_int, "tracy_depth", tracy_depth_option);
    // Link the Tracy package to the executable
    exe.addPackage(std.build.Pkg{
        .name = "tracy",
        .source = .{ .path = "libs/tracy/tracy.zig" },
        .dependencies = &[_]std.build.Pkg{
            .{ .name = "tracy_options", .source = tracy_options.getSource() },
        },
    });
    // If the path to Tracy's source code is specified
    if (tracy_path_option) |tracy_path| {
        // Define the path to the Tracy's client source file
        const client_cpp_path = fs.path.join(
            b.allocator,
            &[_][]const u8{ tracy_path, "public", "TracyClient.cpp" },
        ) catch unreachable;
        // Define the path to the Tracy's C Header
        const c_header_path = fs.path.join(
            b.allocator,
            &[_][]const u8{ tracy_path, "public", "tracy" },
        ) catch unreachable;
        // Define C flags for the compilation of the client source file
        const tracy_c_flags: []const []const u8 = &[_][]const u8{ "-DTRACY_ENABLE=1", "-fno-sanitize=undefined" };
        // Add the C header to the include path
        exe.addIncludePath(c_header_path);
        // Compile the client source file
        exe.addIncludePath(tracy_path);
        exe.addCSourceFile(client_cpp_path, tracy_c_flags);
        exe.linkLibCpp();
        exe.linkLibC();
    }
}
