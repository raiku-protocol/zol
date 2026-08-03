const std = @import("std");
const syscalls = @import("syscalls.zig");
const assert = std.debug.assert;
const Limit = std.Io.Limit;

const debug_buffer_size = 1024;
var debug_buffer: [debug_buffer_size]u8 = undefined;

fn printInner(T: type, thing: T) void {
    _ = thing; // autofix
}

pub fn print(thing: anytype) void {
    const tp = @TypeOf(thing);
    switch (@typeInfo(tp)) {
        .@"struct" => |st| {
            _ = st; // autofix
        },
        .array => |a| {
            _ = a; // autofix
            syscalls.log("gubb");
        },
        .vector => |f| {
            _ = f; // autofix
            syscalls.log("gubba");
        },
        .pointer => |p| {
            _ = p; // autofix
            syscalls.log("gubberoo");
        },
        else => {
            syscalls.log("unprintable");
            syscalls.log(@typeName(tp));
        },
    }
}
