//! Core Solana types

const std = @import("std");
const ProgramError = @import("errors.zig").ProgramError;

/// Public key type
pub const Pubkey = [32]u8;

/// Maximum number of accounts in a transaction
pub const MAX_TX_ACCOUNTS: usize = 254; // u8::MAX - 1

/// Value used to indicate that a serialized account is not a duplicate
pub const NON_DUP_MARKER: u8 = 0xFF;

/// Maximum permitted data increase per instruction
pub const MAX_PERMITTED_DATA_INCREASE: usize = 10 * 1024;

/// BPF alignment for u128
pub const BPF_ALIGN_OF_U128: usize = 8;

/// Compare two pubkeys for equality (optimized)
pub fn pubkeyEq(p1: *const Pubkey, p2: *const Pubkey) bool {
    const p1_ptr = @as([*]const u64, @ptrCast(@alignCast(p1)));
    const p2_ptr = @as([*]const u64, @ptrCast(@alignCast(p2)));

    return p1_ptr[0] == p2_ptr[0] and
        p1_ptr[1] == p2_ptr[1] and
        p1_ptr[2] == p2_ptr[2] and
        p1_ptr[3] == p2_ptr[3];
}

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
