const std = @import("std");
const fs = std.fs;

const deps = @import("deps.zig");

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

    // Create an option to enable Tracy integration
    const tracy_enabled_option = b.option(
        bool,
        "tracy",
        "Enable Tracy integration",
    ) orelse false;
    // Create an option to override Tracy's default call stack capture depth
    const tracy_depth_option = b.option(
        c_int,
        "tracy-depth",
        "Override Tracy's default call stack capture depth",
    ) orelse 0;
    // Add these options to a separate group of options
    const tracy_options = b.addOptions();
    exe.addOptions("tracy_options", tracy_options);
    tracy_options.addOption(bool, "tracy", tracy_enabled_option);
    tracy_options.addOption(c_int, "tracy_depth", tracy_depth_option);
    // Link the Tracy package to the executable
    if (deps.pkgs.tracy.pkg) |tracy_pkg| {
        // Add the options as a dependency to the Tracy package
        exe.addPackage(std.build.Pkg{
            .name = "tracy",
            .source = .{ .path = tracy_pkg.source.path },
            .dependencies = &[_]std.build.Pkg{
                .{ .name = "tracy_options", .source = tracy_options.getSource() },
            },
        });
        // If Tracy integration is enabled, link the libraries
        if (tracy_enabled_option) {
            // Gotta call this snippet until there is a nicer way
            inline for (comptime std.meta.declarations(deps.package_data)) |decl| {
                const pkg = @as(deps.Package, @field(deps.package_data, decl.name));
                for (pkg.system_libs) |item| {
                    exe.linkSystemLibrary(item);
                }
                inline for (pkg.c_include_dirs) |item| {
                    exe.addIncludePath(@field(deps.dirs, decl.name) ++ "/" ++ item);
                }
                inline for (pkg.c_source_files) |item| {
                    exe.addCSourceFile(@field(deps.dirs, decl.name) ++ "/" ++ item, pkg.c_source_flags);
                }
            }
        }
    }
}
