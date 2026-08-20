const std = @import("std");
const zol = @import("zol");

const Account = zol.Account;
const Entrypoint = zol.Entrypoint;

const Error = error{
    NoHello,
} || zol.BuiltinError;

const Tag = enum(u64) {
    Friendly = 0,
    Threatening = 1,
    Deutsch = 2,
    _,
};

export fn entrypoint(input: [*]align(8) u8) u64 {
    var entry = Entrypoint.parse(input);
    dispatch(&entry) catch |e| {
        switch (e) {
            error.NoHello => return 1,
            else => |builtin| return zol.errorToU64(builtin),
        }
    };

    return 0;
}

fn dispatch(entry: *Entrypoint) Error!void {
    switch (@as(Tag, @enumFromInt(std.mem.bytesToValue(u64, entry.data[0..8])))) {
        Tag.Friendly => zol.logMsg(
            \\Hello world!
        ),
        Tag.Threatening => zol.logMsg(
            \\Nice world you've got there, would be a shame if something happened to it...
        ),
        Tag.Deutsch => zol.logMsg(
            \\Hallöchen Weltchen!
        ),
        else => return error.NoHello,
    }
}
