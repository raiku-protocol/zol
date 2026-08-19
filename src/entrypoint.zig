//! Solana program entrypoint and input deserialization

const std = @import("std");
const syscalls = @import("syscalls.zig");
const constants = @import("constants.zig");
const types = @import("types.zig");
const abi = @import("abi.zig");
const errors = @import("errors.zig");
const log = @import("log.zig");
const zol = @import("root.zig");

const Pubkey = types.Pubkey;
const Account = types.Account;
const BuiltinError = errors.Builtin;

pub const Args = struct {
    program_id: Pubkey,
    accounts: []Account,
    data: []const u8,
};

pub const Parser = struct {
    input: [*]u8,

    const Self = @This();

    fn readU64(self: *Self) u64 {
        const u = std.mem.bytesToValue(u64, self.input[0..8]);
        self.input = self.input[8..];
        return u;
    }

    fn readSlice(self: *Self, len: usize) []const u8 {
        const slice = self.input[0..len];
        self.input = self.input[len..];
        return slice;
    }

    fn peek(self: *Self) u8 {
        return self.input[0];
    }

    fn advanceWord(self: *Self) void {
        self.input = self.input[8..];
    }

    fn readAccount(self: *Self) Account {
        const acc: *abi.Account = @ptrCast(@alignCast(self.input));
        self.input = self.input[@sizeOf(abi.Account)..];

        const buffer_len = acc.data_len + constants.growth_buffer_size;
        const buffer = self.input[0..buffer_len];

        // we want to align _AND_ skip 8 bytes (rent epoch)
        const seven: usize = 7;
        const aligned: usize = (buffer_len + 7) & ~seven;
        const skip_epoch = aligned + 8;

        self.input = self.input[skip_epoch..];

        return .{
            .inner = acc,
            .buffer = buffer,
            .permissions = .{
                .signer = acc.signer != 0,
                .writable = acc.writable != 0,
            },
        };
    }

    fn readPubkey(self: *Self) Pubkey {
        var bytes: [32]u8 = undefined;
        std.mem.copyForwards(u8, &bytes, self.readSlice(32));
        return .{
            .bytes = bytes,
        };
    }
};

pub fn parseArgs(
    input: [*]align(8) u8,
    accounts: []Account,
) Args {
    var parser: Parser = .{ .input = input };

    const num_accounts = parser.readU64();

    for (0..num_accounts) |i| {
        const peek = parser.peek();
        if (peek == 0xff) {
            if (i < accounts.len) accounts[i] = parser.readAccount();
        } else {
            if (i < accounts.len) accounts[i] = accounts[peek];
            parser.advanceWord();
        }
    }

    const instruction_data_len = parser.readU64();
    const data = parser.readSlice(instruction_data_len);
    const program_id = parser.readPubkey();

    return .{
        .data = data,
        .program_id = program_id,
        .accounts = accounts[0..@min(accounts.len, num_accounts)],
    };
}
