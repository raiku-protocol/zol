const syscalls = @import("../syscalls.zig");
const Pubkey = @import("../types.zig").Pubkey;

const Rent = @This();

const rent_addr = Pubkey.b58("SysvarRent111111111111111111111111111111111");
pub const account_storage_overhead: u64 = 128;

lamports_per_byte: u64,

pub fn get() Rent {
    var rent: Rent = undefined;
    _ = syscalls.sol_get_sysvar(
        @ptrCast(&rent_addr),
        @ptrCast(&rent),
        0,
        @sizeOf(Rent),
    );
    return rent;
}

pub fn minimum_balance(self: Rent, data_len: u64) u64 {
    return (account_storage_overhead + data_len) * self.lamports_per_byte;
}
