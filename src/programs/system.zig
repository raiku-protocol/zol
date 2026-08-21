const std = @import("std");

const constants = @import("../constants.zig");
const Cpi = @import("../cpi.zig").Cpi;
const Heap = @import("../Heap.zig");
const types = @import("../types.zig");
const Account = types.Account;
const Pubkey = types.Pubkey;
const Signer = types.Signer;

pub const CreateAccount = struct {
    from: Account,
    to: Account,
    data: Data,

    const Data = packed struct {
        discriminator: u32 = 0,
        lamports: u64,
        space: u64,
        owner: Pubkey,
    };

    pub fn invoke(self: CreateAccount, heap: *Heap) !void {
        const cpi: Cpi(Data) = .{
            .program_id = &constants.system_program_id,
            .accounts = &.{ self.from, self.to },
            .data = self.data,
        };
        return cpi.invoke(
            heap,
        );
    }
};

pub const Transfer = struct {
    from: Account,
    to: Account,
    data: Data,

    const Data = packed struct {
        discriminator: u32 = 2,
        lamports: u64,
    };

    pub fn invoke(self: Transfer, heap: *Heap) !void {
        const cpi: Cpi(Data) = .{
            .program_id = &constants.system_program_id,
            .accounts = &.{ self.from, self.to },
            .data = self.data,
        };
        return cpi.invoke(
            heap,
        );
    }
};

pub const Assign = struct {
    account: Account,
    data: Data,
    signers: []const Signer = &.{},

    const Data = packed struct {
        discriminator: u32 = 1,
        new_owner: Pubkey,
    };

    pub fn invoke(self: Assign, heap: *Heap) !void {
        const cpi: Cpi(Data) = .{
            .program_id = &constants.system_program_id,
            .accounts = &.{self.account},
            .data = self.data,
            .signers = self.signers,
        };
        return cpi.invoke(heap);
    }
};

pub const Allocate = struct {
    to: Account,
    data: Data,
    signers: []const Signer = &.{},

    const Data = packed struct {
        discriminator: u32 = 8,
        space: u64,
    };

    pub fn invoke(self: Allocate, heap: *Heap) !void {
        const cpi: Cpi(Data) = .{
            .program_id = &constants.system_program_id,
            .accounts = &.{self.to},
            .data = self.data,
            .signers = self.signers,
        };
        try cpi.invoke(heap);
    }
};
