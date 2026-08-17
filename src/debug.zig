const std = @import("std");
const syscalls = @import("syscalls.zig");

const DEBUG_BUFFER: *[128]u8 = @ptrFromInt(0x300000000);

const BufWrite = struct {
    offset: usize = 0,

    const Self = @This();

    fn write(self: *Self, bytes: []const u8) void {
        std.mem.copyForwards(u8, DEBUG_BUFFER[self.offset..], bytes);
        self.offset += bytes.len;
    }

    fn writeAddr(self: *Self, addr: usize) void {
        var buf: [@sizeOf(usize)]u8 = undefined;
        std.mem.copyForwards(u8, &buf, std.mem.asBytes(&addr));
        for (0..buf.len) |i| {
            self.writeHex(buf[@sizeOf(usize) - i - 1]);
        }
    }

    fn writeHex(self: *Self, byte: u8) void {
        self.writeNibble((byte & 0xf0) >> 4);
        self.writeNibble(byte & 0x0f);
    }

    fn writeNibble(self: *Self, nibble: u8) void {
        const chr = &DEBUG_BUFFER[self.offset];
        if (nibble < 10) chr.* = nibble + "0"[0] else chr.* = nibble - 10 + "a"[0];
        self.offset += 1;
    }

    fn writeAscii(self: *Self, char: u8) void {
        if (char == 0) {
            self.write("○");
        } else if (char == "\n"[0]) {
            self.write("␤");
        } else if (char == "\\"[0] or char == "\""[0]) {
            // unprintable in escaped string
            self.write("⨯");
        } else if (std.ascii.isPrint(char)) {
            self.write(&.{char});
        } else {
            self.write("·");
        }
    }

    fn logAndReset(self: *Self) void {
        syscalls.log(DEBUG_BUFFER[0..self.offset]);
        self.offset = 0;
    }
};

pub fn debug(data: []const u8) void {
    var bw: BufWrite = .{};

    const start = @intFromPtr(data.ptr);

    if (data.len == 0) {
        bw.write("empty data at ");
        bw.writeAddr(start);
        bw.logAndReset();
        return;
    }

    var skip = start % 8;
    var offset: usize = 0;

    const addr = start - skip;
    const rows = (data.len + skip - 1) / 8 + 1;

    for (0..rows) |_| {
        bw.write("|");
        bw.writeAddr(addr + offset);
        bw.write("| ");

        var row_offset: usize = 0;

        for (0..skip) |_| {
            bw.write("░░ ");
        }
        for (0..8 - skip) |_| {
            if (offset + row_offset < data.len) {
                bw.writeHex(data[offset + row_offset]);
                bw.write(" ");
                row_offset += 1;
            } else {
                bw.write("   ");
            }
        }
        // ascii
        bw.write("| ");
        row_offset = 0;
        for (0..skip) |_| {
            bw.write("░");
        }
        for (0..8 - skip) |_| {
            if (offset + row_offset < data.len) {
                bw.writeAscii(data[offset + row_offset]);
                row_offset += 1;
            } else {
                bw.write(" ");
            }
        }
        offset += 8 - skip;
        skip = 0;
        bw.write("|");
        bw.logAndReset();
    }
}
