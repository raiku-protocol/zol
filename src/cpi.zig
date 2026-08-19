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

pub const Instruction = struct {
    program_id: Pubkey,
    data: []const u8,
    account_info: []abi.AccountInfo,
    account_meta: []abi.AccountMeta,

    const Self = @This();

    pub fn init(account: Account, data: []const u8, accounts: []const Account) Self {
        var heap: Heap = .{};

        var account_info = heap.alloc(abi.AccountInfo, accounts.len);
        var account_meta = heap.alloc(abi.AccountMeta, accounts.len);

        for (0..accounts.len) |i| {
            const a = &accounts[i];
            account_meta[i] = .{
                .address = &a.inner.address,
                .signer = a.permissions.signer,
                .writable = a.permissions.writable,
            };
            account_info[i] = a.info();
        }

        return .{
            .program_id = account.inner.address,
            .account_info = account_info,
            .account_meta = account_meta,
            .data = data,
        };
    }

    pub fn invoke(self: Self) !void {
        var sol_signers: [0]abi.SignerSeedsC = undefined;

        const instruction = abi.CInstruction{
            .program_id = &self.program_id,
            .accounts = &self.account_meta[0],
            .accounts_len = self.account_meta.len,
            .data = &self.data[0],
            .data_len = self.data.len,
        };

        const result = syscalls.sol_invoke_signed_c(
            @ptrCast(&instruction),
            @ptrCast(&self.account_info[0]),
            self.account_meta.len,
            @ptrCast(&sol_signers),
            0,
        );

        if (result != errors.SUCCESS) {
            return error.InvalidArgument;
        }
    }
};

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
