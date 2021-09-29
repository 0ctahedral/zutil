const std = @import("std");
const Builder = std.build.Builder;
const builtin = @import("builtin");

pub fn build(b: *Builder) void {
    const build_mode = b.standardReleaseOptions();

    // internal tests
    const internal_test_step = b.addTest("src/tests.zig");
    internal_test_step.setBuildMode(build_mode);

    // api tests
    const test_step = b.addTest("tests/tests.zig");
    // add the packages we are declaring
    addZutil(test_step, "./");
    test_step.setBuildMode(build_mode);

    const test_cmd = b.step("test", "Test the library");
    test_cmd.dependOn(&internal_test_step.step);
    test_cmd.dependOn(&test_step.step);
}

pub fn addZutil(
    artifact: *std.build.LibExeObjStep,
    comptime prefix_path: []const u8,
) void {
    artifact.addPackagePath("zutil", prefix_path ++ "src/zutil.zig");
}
