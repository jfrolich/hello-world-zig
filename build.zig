const std = @import("std");
// const deps = @import("deps.zig");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    // const exe = b.addExecutable("hello-world-zig", "src/main.zig");
    const lib = b.addSharedLibrary("hello-world-zig", "src/main.zig", b.version(0, 0, 0));

    lib.setTarget(target);
    lib.setBuildMode(mode);
    lib.use_stage1 = true;
    // deps.addAllTo(exe);
    // const run_cmd = exe.run();
    // run_cmd.step.dependOn(b.getInstallStep());
    // if (b.args) |args| {
    //     run_cmd.addArgs(args);
    // }

    const sqlite = b.addStaticLibrary("sqlite", null);
    sqlite.setTarget(target);
    sqlite.setBuildMode(mode);
    sqlite.linkLibC();
    sqlite.linkSystemLibrary("c");
    sqlite.addCSourceFile("third_party/zig-sqlite/c/sqlite3.c", &[_][]const u8{
        "-std=c99",                     "-Oz",
        "-DSQLITE_OMIT_LOAD_EXTENSION", "-DSQLITE_DISABLE_LFS",
        "-DSQLITE_ENABLE_FTS3",         "-DSQLITE_ENABLE_FTS3_PARENTHESIS",
        "-DSQLITE_THREADSAFE=0",        "-DSQLITE_ENABLE_NORMALIZE",
    });
    lib.linkLibrary(sqlite);
    lib.addPackagePath("sqlite", "third_party/zig-sqlite/sqlite.zig");
    lib.addIncludePath("third_party/zig-sqlite/c");

    lib.install();
    sqlite.install();

    // const run_step = b.step("run", "Run the app");
    // run_step.dependOn(&run_cmd.step);

    // const exe_tests = b.addTest("src/main.zig");
    // exe_tests.setTarget(target);
    // exe_tests.setBuildMode(mode);

    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&exe_tests.step);
}
