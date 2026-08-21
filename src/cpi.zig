//! Cross-Program Invocation (CPI)

const std = @import("std");

const abi = @import("abi.zig");
const errors = @import("errors.zig");
const BuiltinError = errors.Builtin;
const Heap = @import("Heap.zig");
const syscalls = @import("syscalls.zig");
const types = @import("types.zig");
const Pubkey = types.Pubkey;
const Seed = types.Seed;
const Signer = types.Signer;
const Account = types.Account;
const AccountMeta = types.AccountMeta;
const zol = @import("root.zig");

pub fn Cpi(Data: type) type {
    return struct {
        program_id: *const Pubkey,
        accounts: []const Account = &.{},
        data: Data,
        signers: []const Signer = &.{},

        const Self = @This();

        pub fn invoke(
            self: Self,
            heap: *Heap,
        ) !void {
            var scratch = heap.scratch();

            var account_meta = scratch.alloc(abi.AccountMeta, self.accounts.len);
            var account_info = scratch.alloc(abi.AccountInfo, self.accounts.len);

            for (0..self.accounts.len) |i| {
                const a = &self.accounts[i];
                account_meta[i] = .{
                    .address = &a.inner.address,
                    .signer = a.permissions.signer,
                    .writable = a.permissions.writable,
                };
                account_info[i] = a.abi_info();
            }

            const slice = asBytes(&self.data);

            const instruction: abi.CInstruction = .{
                .program_id = self.program_id.as_bytes(),
                .accounts = account_meta.ptr,
                .accounts_len = self.accounts.len,
                .data = slice.ptr,
                .data_len = slice.len,
            };

            const result = syscalls.sol_invoke_signed_c(
                @ptrCast(&instruction),
                @ptrCast(account_info.ptr),
                self.accounts.len,
                @ptrCast(self.signers.ptr),
                self.signers.len,
            );

            if (result != errors.SUCCESS) {
                return error.InvalidArgument;
            }
        }

        fn asBytes(data: *const Data) []const u8 {
            switch (@typeInfo(Data)) {
                .@"struct" => |s| {
                    switch (s.layout) {
                        .@"packed" => {
                            comptime var bitsize = 0;

                            inline for (s.fields) |field| {
                                switch (@typeInfo(field.type)) {
                                    .int => |e| {
                                        bitsize += e.bits;
                                    },
                                    .@"struct" => |inner_struct| {
                                        switch (inner_struct.layout) {
                                            .@"packed" => {
                                                bitsize += @bitSizeOf(inner_struct.backing_integer.?);
                                            },
                                            else => @compileError("Unsupported data field type"),
                                        }
                                    },
                                    else => @compileError("Unsupported data field type"),
                                }
                            }
                            if (bitsize % 8 != 0) @compileError("Data struct bitsize needs to be a multiple of 8");

                            const data_ptr: [*]const u8 = @ptrCast(data);
                            return data_ptr[0 .. bitsize / 8];
                        },
                        else => @compileError("sub-struct needs to be packed as well"),
                    }
                },
                .pointer => {
                    return data.*;
                },
                .int => |i| {
                    if (i.bits % 8 != 0) @compileError("Integer bitsize needs to be a multiple of 8");
                    return std.mem.asBytes(data);
                },
                else => @compileError("Unsupported data type"),
            }
        }
    };
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
