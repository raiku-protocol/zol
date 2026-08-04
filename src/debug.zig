const std = @import("std");
const syscalls = @import("syscalls.zig");
const assert = std.debug.assert;
const Limit = std.Io.Limit;

const debug_buffer_size = 1024;
var debug_buffer: [debug_buffer_size]u8 = undefined;
