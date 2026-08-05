//! Core Solana types
const std = @import("std");
const base58 = @import("base58");

const ProgramError = @import("errors.zig").ProgramError;

/// Public key type
pub const Pubkey = extern struct {
    bytes: [32]u8 align(8),

    pub fn eq(a: *const @This(), b: *const @This()) bool {
        return std.mem.eql(u8, &a.bytes, &b.bytes);
    }

    pub fn b58(comptime str: []const u8) @This() {
        return parse(str) catch @compileError("Invalid encoding");
    }

    pub fn parse(bytes: []const u8) !@This() {
        var buf: [32]u8 = undefined;
        const slice = try base58.decode(&buf, bytes);
        if (slice.len != buf.len) return error.InvalidPubkey;
        return .{ .bytes = buf };
    }
};

/// Maximum number of accounts in a transaction
pub const MAX_TX_ACCOUNTS: usize = 254; // u8::MAX - 1

/// Value used to indicate that a serialized account is not a duplicate
pub const NON_DUP_MARKER: u8 = 0xFF;

/// Maximum permitted data increase per instruction
pub const PADDING: usize = 10 * 1024;

/// BPF alignment for u128
pub const BPF_ALIGN_OF_U128: usize = 8;

pub const MAX_PERMITTED_DATA_INCREASE: usize = 10 * 1024;

/// Raw account data structure (matches Solana's memory layout)
pub const Account = extern struct {
    duplicate_marker: u8,
    is_signer: u8,
    is_writable: u8,
    executable: u8,
    padding: [4]u8,

    key: Pubkey,
    owner: Pubkey,
    lamports: u64,
    data_len: u64,

    // Account data follows immediately in memory after this struct
    pub fn data(self: *const @This()) []u8 {
        const memory_address = @intFromPtr(self) + @sizeOf(@This());
        const ptr: [*]u8 = @ptrFromInt(memory_address);
        return ptr[0..self.data_len];
    }

    pub fn serialized_size(self: *const @This()) usize {
        const body_data_grow = @sizeOf(Account) + self.data_len + PADDING;
        const alignment = body_data_grow % 8;
        const rent_epoch_unused = 8;
        return body_data_grow + alignment + rent_epoch_unused;
    }
};
