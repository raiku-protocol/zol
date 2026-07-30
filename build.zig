const std = @import("std");

pub fn build(b: *std.Build) !void {
    _ = b.addModule("sdk", .{ .root_source_file = b.path("src/root.zig") });
}

/// Takes care of setting up everything needed to create a solana v3
/// compatible {name}.so from provided source root
pub fn build_so(caller_b: *std.Build, name: []const u8, source: []const u8) void {
    const obj = object(caller_b, name, source);
    const sdk = caller_b.dependencyFromBuildZig(@This(), .{}).module("sdk");
    obj.root_module.addImport("sdk", sdk);
    const out = link(caller_b, obj);
    const ins = caller_b.addInstallFile(out, caller_b.fmt("{s}.so", .{name}));
    caller_b.getInstallStep().dependOn(&ins.step);
}

pub fn object(caller_b: *std.Build, name: []const u8, source: []const u8) *std.Build.Step.Compile {
    return caller_b.addObject(.{
        .name = name,
        .root_module = caller_b.createModule(.{
            .root_source_file = caller_b.path(source),
            .target = caller_b.resolveTargetQuery(.{
                .cpu_arch = .bpfel,
                .os_tag = .freestanding,
                .cpu_model = .{ .explicit = &std.Target.bpf.cpu.v2 },
            }),
            .optimize = std.builtin.OptimizeMode.ReleaseSmall,
        }),
    });
}

pub fn link(caller_b: *std.Build, obj: *std.Build.Step.Compile) std.Build.LazyPath {
    const linker = caller_b.dependencyFromBuildZig(@This(), .{})
        .builder
        .dependency("elf2sbpf", .{})
        .artifact("elf2sbpf");

    const linker_run = caller_b.addRunArtifact(linker);

    const o_path = obj.out_filename;
    const so_path = switchExt(caller_b, o_path, ".so");

    const workdir = caller_b.addWriteFiles();
    const o_file = workdir.addCopyFile(obj.getEmittedBin(), o_path);

    linker_run.setCwd(workdir.getDirectory());

    linker_run.addArg("--v3");
    _ = linker_run.addFileArg(o_file);
    return linker_run.addOutputFileArg(so_path);
}

// attribution: github/allyourcodebase/ffmpeg
fn switchExt(b: *std.Build, path: []const u8, new_extension: []const u8) []const u8 {
    const basename = std.fs.path.basename(path);
    const ext = std.fs.path.extension(basename);
    return b.fmt("{s}{s}", .{ basename[0 .. basename.len - ext.len], new_extension });
}
