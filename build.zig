const std = @import("std");

pub fn build(b: *std.Build) !void {
    _ = b.addModule("zol", .{ .root_source_file = b.path("src/root.zig") });
}

/// Takes care of setting up everything needed to create a solana v3
/// compatible {name}.so from provided source root
pub fn build_so(b: *std.Build, name: []const u8, root: []const u8) void {
    const zig_exe = b.graph.zig_exe;
    const zol_b = b.dependencyFromBuildZig(@This(), .{})
        .builder;

    const workdir = b.addWriteFiles();

    const run_build_lib = b.addSystemCommand(&.{ zig_exe, "build-lib" });
    run_build_lib.setCwd(workdir.getDirectory());
    run_build_lib.addArgs(&.{ "-target", "bpfel-freestanding" });
    run_build_lib.addArgs(&.{"-mcpu=v2"});
    run_build_lib.addArgs(&.{ "-O", "ReleaseSmall" });
    const bc_file = run_build_lib.addPrefixedOutputFileArg("-femit-llvm-bc=", b.fmt("{s}.bc", .{name}));
    run_build_lib.addArgs(&.{"-fno-emit-bin"});

    run_build_lib.addArgs(&.{ "--dep", "zol" });
    run_build_lib.addPrefixedFileArg("-Mroot=", b.path(root));
    run_build_lib.addPrefixedFileArg("-Mzol=", zol_b.path("src/root.zig"));

    const run_cc = b.addSystemCommand(&.{ zig_exe, "cc" });
    run_cc.setCwd(workdir.getDirectory());
    run_cc.addArgs(&.{ "-target", "bpfel-freestanding" });
    run_cc.addArgs(&.{"-mcpu=v2"});
    run_cc.addArgs(&.{"-O2"});
    run_cc.addArgs(&.{"-mllvm"});
    run_cc.addArgs(&.{"-bpf-stack-size=4096"});
    run_cc.addArgs(&.{"-c"});
    run_cc.addFileArg(bc_file);
    run_cc.addArgs(&.{"-o"});
    const o_file = run_cc.addOutputFileArg(b.fmt("{s}.o", .{name}));

    const linker = zol_b
        .dependency("elf2sbpf", .{})
        .artifact("elf2sbpf");

    const run_linker = b.addRunArtifact(linker);
    const so_path = b.fmt("{s}.so", .{name});

    run_linker.setCwd(workdir.getDirectory());
    run_linker.addArg("--v3");
    _ = run_linker.addFileArg(o_file);

    const so_file = run_linker.addOutputFileArg(so_path);

    const ins = b.addInstallFile(so_file, so_path);
    b.getInstallStep().dependOn(&ins.step);
}
