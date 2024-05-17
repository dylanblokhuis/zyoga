const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});
    const shared = b.option(bool, "shared", "Compile as shared library instead of static");
    const name = "zyoga";

    const lib = if (shared != null and shared.? == true) b.addSharedLibrary(.{
        .name = name,
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    }) else b.addStaticLibrary(.{
        .name = name,
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    lib.linkLibCpp();

    _ = b.addModule(name, .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/root.zig"),
    });

    const yoga_dep = b.dependency("yoga", .{});

    const yoga_files = &.{
        "yoga/YGNodeStyle.cpp",
        "yoga/YGValue.cpp",
        "yoga/YGEnums.cpp",
        "yoga/YGNodeLayout.cpp",
        "yoga/node/Node.cpp",
        "yoga/node/LayoutResults.cpp",
        "yoga/config/Config.cpp",
        "yoga/debug/Log.cpp",
        "yoga/debug/AssertFatal.cpp",
        "yoga/event/event.cpp",
        "yoga/algorithm/Baseline.cpp",
        "yoga/algorithm/CalculateLayout.cpp",
        "yoga/algorithm/AbsoluteLayout.cpp",
        "yoga/algorithm/Cache.cpp",
        "yoga/algorithm/FlexLine.cpp",
        "yoga/algorithm/PixelGrid.cpp",
        "yoga/YGPixelGrid.cpp",
        "yoga/YGNode.cpp",
        "yoga/YGConfig.cpp",
    };

    lib.addIncludePath(yoga_dep.path(""));
    const flags = &.{"-std=c++20"};
    inline for (yoga_files) |file| {
        lib.addCSourceFile(.{ .file = yoga_dep.path(file), .flags = flags });
    }

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
    b.installArtifact(lib);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
