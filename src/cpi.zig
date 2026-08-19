//! Cross-Program Invocation (CPI)

const std = @import("std");
const zol = @import("root.zig");
const types = @import("types.zig");
const abi = @import("abi.zig");
const errors = @import("errors.zig");
const syscalls = @import("syscalls.zig");

const Pubkey = types.Pubkey;
const Account = types.Account;
const AccountMeta = types.AccountMeta;
const BuiltinError = errors.Builtin;

// /// Instruction for cross-program invocation
// pub const Instruction = struct {
//     program_id: *const Pubkey,
//     accounts: []const types.SolAccountMeta,
//     data: []const u8,
// };

pub fn Instruction(comptime n: u64) type {
    return struct {
        program_id: Pubkey,
        data: []const u8,
        account_info: [n]abi.AccountInfo,
        account_meta: [n]abi.AccountMeta,

        const Self = @This();

        pub fn init(account: Account, data: []const u8, accounts: [n]AccountMeta) Self {
            var account_info: [n]abi.AccountInfo = undefined;
            var account_meta: [n]abi.AccountMeta = undefined;

            for (0..n) |i| {
                const a = &accounts[i];
                account_meta[i] = .{
                    .address = &a.inner.inner.address,
                    .signer = a.opts.signer,
                    .writable = a.opts.writable,
                };
                account_info[i] = a.inner.info();
            }

            return .{
                .program_id = account.inner.address,
                .account_info = account_info,
                .account_meta = account_meta,
                .data = data,
            };
        }

        pub fn invoke(self: Self) !void {
            // TODO optional validation
            for (self.account_meta) |account_meta| {
                var found = false;
                for (self.account_info) |account_info| {
                    if (account_meta.address.eq(account_info.address)) {
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    zol.logMsg("ohno");
                    return error.NotEnoughAccountKeys;
                }
                zol.logMsg("yoss");
            }

            var sol_signers: [0]abi.SignerSeedsC = undefined;

            const instruction = abi.CInstruction{
                .program_id = &self.program_id,
                .accounts = &self.account_meta[0],
                .accounts_len = n,
                .data = &self.data[0],
                .data_len = self.data.len,
            };

            // ok

            const result = syscalls.sol_invoke_signed_c(
                @ptrCast(&instruction),
                @ptrCast(&self.account_info[0]),
                n,
                @ptrCast(&sol_signers),
                0,
            );

            if (result != errors.SUCCESS) {
                return error.InvalidArgument;
            }
        }
    };
}

/// Instruction for cross-program invocation
pub const InstructionCpi = struct {
    program_id: *const Pubkey,
    accounts: []types.SolAccountMeta,
    data: []const u8,
};

/// Invoke another program
///
/// # Arguments
/// * `instruction` - The instruction to invoke
/// * `accounts` - Account infos required by the instruction
///
/// # Errors
/// Returns error if the invocation fails
pub fn invoke(
    instruction: *const Instruction,
    accounts: []*Account,
) errors.ProgramError!void {
    return invokeSigned(instruction, accounts, &[_][]const u8{});
}

/// Invoke another program with program derived address signatures
///
/// # Arguments
/// * `instruction` - The instruction to invoke
/// * `accounts` - Account infos required by the instruction
/// * `signers_seeds` - Seeds used to derive PDAs that should sign (array of seed arrays)
///
/// # Errors
/// Returns error if the invocation fails
pub fn invokeSigned(
    instruction: *const Instruction,
    accounts: []Account,
    signers_seeds: []const []const u8,
) BuiltinError!void {
    // Convert instruction to C ABI format
    const sol_instruction = abi.Instruction{
        .program_id = instruction.program_id,
        .accounts = instruction.accounts.ptr,
        .accounts_len = instruction.accounts.len,
        .data = instruction.data.ptr,
        .data_len = instruction.data.len,
    };

    var sol_account_infos: [32]types.SolAccountInfo = undefined;
    if (accounts.len > sol_account_infos.len) {
        return error.InvalidArgument;
    }

    // Convert AccountInfo to SolAccountInfo format
    // Memory layout: [Account struct][account data immediately after]
    for (accounts, 0..) |account, i| {
        // Data follows immediately after Account struct
        sol_account_infos[i] = .{
            .key = &account.pubkey(),
            .lamports = &account.lamports(),
            .data_len = account.data().len,
            .data = account.data().ptr,
            .owner = &account.owner(),
            .rent_epoch = 0, // Not used in CPI
            .signer = account.signer(),
            .writable = account.writable(),
            .executable = account.executable(),
        };
    }

    // Serialize signer seeds to C ABI format if provided
    // For single PDA signing (most common case), seeds are passed as a single array
    // Using small array to avoid sBPF stack overflow
    var sol_signer_seeds: [4]abi.SignerSeedC = undefined;
    var sol_signers: [1]abi.Signer = undefined;

    const signers_ptr: [*]const u8 = if (signers_seeds.len > 0) blk: {
        // Convert each seed to SolSignerSeedC
        if (signers_seeds.len > sol_signer_seeds.len) {
            return error.InvalidArgument;
        }

        for (signers_seeds, 0..) |seed, i| {
            sol_signer_seeds[i] = abi.SignerSeedC{
                .addr = @intFromPtr(seed.ptr),
                .len = seed.len,
            };
        }

        // Create the signers array (one PDA)
        sol_signers[0] = abi.SignerSeedsC{
            .addr = @intFromPtr(&sol_signer_seeds),
            .len = signers_seeds.len,
        };

        break :blk @as([*]const u8, @ptrCast(&sol_signers));
    } else blk: {
        break :blk @as([*]const u8, @ptrCast(&sol_signers));
    };

    const signers_len: u64 = if (signers_seeds.len > 0) 1 else 0;

    // compiler fence not to reorder anything before syscall?
    const result = syscalls.sol_invoke_signed_c(
        @as([*]const u8, @ptrCast(&sol_instruction)),
        @as([*]const u8, @ptrCast(&sol_account_infos)),
        accounts.len,
        signers_ptr,
        signers_len,
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
