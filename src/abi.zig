pub const Pubkey = @import("types.zig").Pubkey;

pub const AccountInfo = extern struct {
    address: *const Pubkey,
    lamports: *u64,
    data_len: u64,
    data: [*]u8,
    owner: *const Pubkey,
    /// rent_epoch is deprecated
    _deprecated: u64 = 0,
    signer: u8,
    writable: u8,
    executable: u8,
    padding: u8 = 0,
};

pub const Account = extern struct {
    duplicate: u8,
    signer: u8,
    writable: u8,
    executable: u8,
    padding: [4]u8 = @splat(0),
    address: Pubkey,
    owner: Pubkey,
    lamports: u64,
    data_len: u64,
};

/// C-ABI signer seed (SolSignerSeedC in Agave)
pub const SignerSeedC = extern struct {
    addr: u64,
    len: u64,
};

/// C-ABI signer seeds (SolSignerSeedsC in Agave)
pub const SignerSeedsC = extern struct {
    addr: u64,
    len: u64,
};

pub const AccountMeta = extern struct {
    address: *const Pubkey,
    writable: bool,
    signer: bool,
};

pub const CInstruction = extern struct {
    program_id: *const Pubkey,
    accounts: [*]const AccountMeta,
    accounts_len: u64,
    data: [*]const u8,
    data_len: u64,
};
