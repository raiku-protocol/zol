//! Solana program entrypoint and input deserialization

const std = @import("std");
const types = @import("types.zig");
const errors = @import("errors.zig");

const Pubkey = types.Pubkey;
const Account = types.Account;
const BuiltinError = errors.Builtin;
const NON_DUP_MARKER = types.NON_DUP_MARKER;
const MAX_PERMITTED_DATA_INCREASE = types.MAX_PERMITTED_DATA_INCREASE;
const BPF_ALIGN_OF_U128 = types.BPF_ALIGN_OF_U128;

/// Heap start address for BPF programs
pub const HEAP_START_ADDRESS: u64 = 0x300000000;

/// Heap length (32KB)
pub const HEAP_LENGTH: usize = 32 * 1024;

/// Static account data size (account header + max data increase)
const STATIC_ACCOUNT_DATA: usize = @sizeOf(Account) + MAX_PERMITTED_DATA_INCREASE;

/// Align pointer to BPF u128 alignment
inline fn alignPointer(ptr: usize) usize {
    return (ptr + (BPF_ALIGN_OF_U128 - 1)) & ~(BPF_ALIGN_OF_U128 - 1);
}

pub const Args = struct {
    program_id: *const Pubkey,
    accounts: []*Account,
    data: []align(8) u8,
};

pub fn parseArgs(
    input: [*]u8,
    accounts_buffer: []*Account,
) Args {
    var ptr = input;
    const max_accounts = accounts_buffer.len;

    // Read number of accounts
    const num_accounts_ptr = @as(*const u64, @ptrCast(@alignCast(ptr)));
    const num_accounts: usize = @intCast(num_accounts_ptr.*);
    ptr += @sizeOf(u64);

    var accounts_count: usize = 0;

    if (num_accounts > 0) {
        // Limit to buffer capacity
        const to_process = if (num_accounts > max_accounts) max_accounts else num_accounts;
        var to_skip = num_accounts - to_process;

        var i: usize = 0;
        while (i < to_process) : (i += 1) {
            const account_ptr = @as(*Account, @ptrCast(@alignCast(ptr)));

            // Skip 8 bytes (rent epoch or duplicate marker + padding)
            ptr += @sizeOf(u64);

            if (account_ptr.duplicate_marker != NON_DUP_MARKER) {
                // Duplicate account - reference existing account
                const dup_index = account_ptr.duplicate_marker;
                accounts_buffer[i] = accounts_buffer[dup_index];
            } else {
                // New account
                accounts_buffer[i] = account_ptr;

                // Skip account struct + data
                ptr += STATIC_ACCOUNT_DATA;
                ptr += @as(usize, @intCast(account_ptr.data_len));

                // Align to u128
                ptr = @ptrFromInt(alignPointer(@intFromPtr(ptr)));
            }
            accounts_count += 1;
        }

        // Skip remaining accounts if buffer was too small
        while (to_skip > 0) : (to_skip -= 1) {
            const account_ptr = @as(*Account, @ptrCast(@alignCast(ptr)));
            ptr += @sizeOf(u64);

            if (account_ptr.duplicate_marker == NON_DUP_MARKER) {
                ptr += STATIC_ACCOUNT_DATA;
                ptr += @as(usize, @intCast(account_ptr.data_len));
                ptr = @ptrFromInt(alignPointer(@intFromPtr(ptr)));
            }
        }
    }

    // Read instruction data length
    const ix_data_len_ptr = @as(*const u64, @ptrCast(@alignCast(ptr)));
    const ix_data_len: usize = @intCast(ix_data_len_ptr.*);
    ptr += @sizeOf(u64);

    // Get instruction data slice
    const instruction_data = ptr[0..ix_data_len];
    ptr += ix_data_len;

    // Get program ID
    const program_id = @as(*const Pubkey, @ptrCast(@alignCast(ptr)));

    return .{
        .program_id = program_id,
        .accounts = accounts_buffer[0..accounts_count],
        .data = @alignCast(instruction_data),
    };
}
