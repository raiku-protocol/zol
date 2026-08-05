const zol = @import("zol");
const std = @import("std");

pub fn build(b: *std.Build) !void {
    const mod = b.addModule("hello", .{
        .root_source_file = b.path("src/hello.zig"),
        .imports = &.{.{
            .name = "zol",
            .module = b.dependency("zol", .{}).module("zol"),
        }},
    });

    const so = zol.build_so(mod);
    const ins = b.addInstallFile(so, "hello.so");
    b.getInstallStep().dependOn(&ins.step);
}
