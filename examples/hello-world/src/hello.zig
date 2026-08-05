const std = @import("std");
const zol = @import("zol");

const Account = zol.Account;
const Args = zol.Args;

const Error = error{
    NoHello,
} || zol.BuiltinError;

const Tag = enum(u64) {
    Friendly = 0,
    Threatening = 1,
    Deutsch = 2,
    _,
};

/// Program entrypoint
export fn entrypoint(input: [*]align(8) u8) u64 {
    var accounts: [1]*Account = undefined;

    dispatch(zol.parseArgs(input, &accounts)) catch |e| {
        switch (e) {
            error.NoHello => return 1,
            else => |builtin| return zol.errorToU64(builtin),
        }
    };

    return 0;
}

fn dispatch(args: Args) Error!void {
    switch (@as(Tag, @enumFromInt(std.mem.bytesToValue(u64, args.data[0..8])))) {
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
