const std = @import("std");

pub fn build(b: *std.Build) !void {
    const root_mod = b.addModule("zol", .{
        .root_source_file = b.path("src/root.zig"),
        .imports = &.{.{
            .name = "base58",
            .module = b.dependency("base58", .{}).module("base58"),
        }},
        .target = b.graph.host,
    });

    const unit_tests = b.addTest(.{ .root_module = root_mod });
    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "run tests");
    test_step.dependOn(&run_unit_tests.step);
}

/// Takes care of setting up everything needed to create a solana v3
/// compatible .so from provided module
pub fn build_so(mod: *std.Build.Module) std.Build.LazyPath {
    const b = mod.owner;

    const zig_exe = b.graph.zig_exe;
    const zol_b = b.dependencyFromBuildZig(@This(), .{})
        .builder;

    const workdir = b.addWriteFiles();

    const run_build_lib = b.addSystemCommand(&.{ zig_exe, "build-lib" });
    run_build_lib.setCwd(workdir.getDirectory());
    run_build_lib.addArgs(&.{ "-target", "bpfel-freestanding" });
    run_build_lib.addArg("-mcpu=v2");
    run_build_lib.addArgs(&.{ "-O", "ReleaseFast" });
    const bc_file = run_build_lib.addPrefixedOutputFileArg("-femit-llvm-bc=", "mod.bc");
    run_build_lib.addArg("-fno-emit-bin");

    for (mod.import_table.keys()) |key| {
        run_build_lib.addArgs(&.{ "--dep", key });
    }

    run_build_lib.addPrefixedFileArg("-Mroot=", mod.root_source_file.?);

    for (mod.import_table.keys()) |key| {
        if (mod.import_table.get(key)) |val| {
            if (std.mem.eql(u8, key, "zol")) {
                for (zol_b.available_deps) |d| {
                    run_build_lib.addArgs(&.{ "--dep", d[0] });
                }
            }

            run_build_lib.addPrefixedFileArg(
                b.fmt("-M{s}=", .{key}),
                val.root_source_file.?,
            );

            if (std.mem.eql(u8, key, "zol")) {
                for (zol_b.available_deps) |d| {
                    run_build_lib.addPrefixedFileArg(
                        b.fmt("-M{s}=", .{d[0]}),
                        zol_b.dependency(d[0], .{}).module(d[0]).root_source_file.?,
                    );
                }
            }
        }
    }

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
    const o_file = run_cc.addOutputFileArg("mod.o");

    const linker = zol_b
        .dependency("elf2sbpf", .{})
        .artifact("elf2sbpf");

    const run_linker = b.addRunArtifact(linker);
    const so_path = "mod.so";

    run_linker.setCwd(workdir.getDirectory());
    run_linker.addArg("--v3");
    _ = run_linker.addFileArg(o_file);

    return run_linker.addOutputFileArg(so_path);
}
