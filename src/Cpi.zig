//! Cross-Program Invocation (CPI)

const std = @import("std");
const zol = @import("root.zig");
const types = @import("types.zig");
const abi = @import("abi.zig");
const errors = @import("errors.zig");
const syscalls = @import("syscalls.zig");
const Heap = @import("Heap.zig");

const Pubkey = types.Pubkey;
const Account = types.Account;
const AccountMeta = types.AccountMeta;
const BuiltinError = errors.Builtin;

const Cpi = @This();

pub fn invoke(program_id: *const Pubkey, accounts: []const Account, data: []const u8) !void {
    var account_meta: [32]abi.AccountMeta = undefined;

    for (0..accounts.len) |i| {
        const a = &accounts[i];
        account_meta[i] = .{
            .address = a.inner.address,
            .signer = a.inner.signer != 0,
            .writable = a.inner.writable != 0,
        };
    }

    var sol_signers: [0]abi.SignerSeedsC = undefined;

    const instruction = abi.CInstruction{
        .program_id = program_id,
        .accounts = &account_meta[0],
        .accounts_len = accounts.len,
        .data = &data[0],
        .data_len = data.len,
    };

    const result = syscalls.sol_invoke_signed_c(
        @ptrCast(&instruction),
        @ptrCast(accounts.ptr),
        accounts.len,
        @ptrCast(&sol_signers),
        0,
    );

    if (result != errors.SUCCESS) {
        return error.InvalidArgument;
    }
}

/// Set return data for this program
///
/// The return data can be retrieved by the caller or by sibling instructions
/// in the same transaction.
pub fn setReturnData(data: []const u8) void {
    syscalls.sol_set_return_data(data.ptr, data.len);
}

/// Get return data from the last CPI call
///
/// Returns a tuple of (program_id, data) if return data exists, or null otherwise
pub fn getReturnData(buffer: []u8) ?struct { Pubkey, []const u8 } {
    var program_id: Pubkey = undefined;

    const len = syscalls.sol_get_return_data(
        buffer.ptr,
        buffer.len,
        &program_id,
    );

    if (len == 0) {
        return null;
    }

    return .{ program_id, buffer[0..@intCast(len)] };
}
