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
pub const MAX_PERMITTED_DATA_INCREASE: usize = 10 * 1024;

/// BPF alignment for u128
pub const BPF_ALIGN_OF_U128: usize = 8;

/// Raw account data structure (matches Solana's memory layout)
pub const Account = extern struct {
    /// 0xFF = unique, index = duplicate of that account
    duplicate_marker: u8,

    /// Indicates whether the transaction was signed by this account
    is_signer: u8,

    /// Indicates whether the account is writable
    is_writable: u8,

    /// Indicates whether this account represents a program
    executable: u8,

    /// Difference between original and current data length
    resize_delta: i32,

    /// Public key of the account
    key: Pubkey,

    /// Program that owns this account
    owner: Pubkey,

    /// The lamports in the account
    lamports: u64,

    /// Length of the data
    data_len: u64,

    // Account data follows immediately in memory after this struct
    pub fn data(self: *const @This()) []u8 {
        const memory_address = @intFromPtr(self) + @sizeOf(@This());
        const ptr: [*]u8 = @ptrFromInt(memory_address);
        return ptr[0..self.data_len];
    }
};
