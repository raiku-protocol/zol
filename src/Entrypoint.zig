//! Solana program entrypoint and input deserialization

const std = @import("std");
const syscalls = @import("syscalls.zig");
const constants = @import("constants.zig");
const Heap = @import("Heap.zig");
const types = @import("types.zig");
const abi = @import("abi.zig");
const errors = @import("errors.zig");
const log = @import("log.zig");
const zol = @import("root.zig");

const Pubkey = types.Pubkey;
const Account = types.Account;
const BuiltinError = errors.Builtin;

pub const Entrypoint = @This();
pub const stack_accounts = 4;

program_id: Pubkey,
accounts: []Account,
data: []const u8,
heap: Heap,

pub fn parse(input: [*]align(8) u8) Entrypoint {
    var parser: Parser = .{ .input = input };
    var heap: Heap = .{};

    const num_accounts = parser.readU64();

    var accounts = heap.alloc(Account, num_accounts);

    for (0..num_accounts) |i| {
        const peek = parser.peek();
        if (peek == 0xff) {
            accounts[i] = parser.readAccount();
        } else {
            accounts[i] = accounts[peek];
            parser.advanceWord();
        }
    }

    const instruction_data_len = parser.readU64();

    return .{
        .data = parser.readSlice(instruction_data_len),
        .program_id = parser.readPubkey(),
        .accounts = accounts,
        .heap = heap,
    };
}

const Parser = struct {
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

        const data: [*]u8 = @ptrCast(self.input);

        const buffer_len = acc.data_len + constants.growth_buffer_size;
        const buffer = self.input[0..buffer_len];
        _ = buffer; // autofix

        // we want to align _AND_ skip 8 bytes (rent epoch)
        const seven: usize = 7;
        const aligned: usize = (buffer_len + 7) & ~seven;
        const skip_epoch = aligned + 8;

        self.input = self.input[skip_epoch..];

        const info: abi.AccountInfo = .{
            .address = &acc.address,
            .lamports = &acc.lamports,
            .data_len = acc.data_len,
            .data = data,
            .owner = &acc.owner,
            .signer = acc.signer,
            .writable = acc.writable,
            .executable = acc.executable,
        };

        return .{
            .inner = info,
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
