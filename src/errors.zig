//! Error types for Solana programs

/// Program execution errors
pub const Builtin = error{
    CustomZero,
    InvalidArgument,
    InvalidInstructionData,
    InvalidAccountData,
    AccountDataTooSmall,
    InsufficientFunds,
    IncorrectProgramId,
    MissingRequiredSignatures,
    AccountAlreadyInitialized,
    UninitializedAccount,
    NotEnoughAccountKeys,
    AccountBorrowFailed,
    MaxSeedLengthExceeded,
    InvalidSeeds,
    BorshIoError,
    AccountNotRentExempt,
    UnsupportedSysvar,
    IllegalOwner,
    MaxAccountsDataAllocationsExceeded,
    InvalidAccountDataRealloc,
    MaxInstructionTraceLengthExceeded,
    BuiltinProgramsMustConsumeComputeUnits,
    InvalidAccountOwner,
    ArithmeticOverflow,
    Immutable,
    IncorrectAuthority,
};

pub const SUCCESS: u64 = 0;

/// Convert Builtin to u64 error code
pub fn errorToU64(err: Builtin) u64 {
    return switch (err) {
        Builtin.CustomZero => 1 << 32,
        Builtin.InvalidArgument => 2 << 32,
        Builtin.InvalidInstructionData => 3 << 32,
        Builtin.InvalidAccountData => 4 << 32,
        Builtin.AccountDataTooSmall => 5 << 32,
        Builtin.InsufficientFunds => 6 << 32,
        Builtin.IncorrectProgramId => 7 << 32,
        Builtin.MissingRequiredSignatures => 8 << 32,
        Builtin.AccountAlreadyInitialized => 9 << 32,
        Builtin.UninitializedAccount => 0 << 32,
        Builtin.NotEnoughAccountKeys => 1 << 32,
        Builtin.AccountBorrowFailed => 2 << 32,
        Builtin.MaxSeedLengthExceeded => 3 << 32,
        Builtin.InvalidSeeds => 4 << 32,
        Builtin.BorshIoError => 5 << 32,
        Builtin.AccountNotRentExempt => 6 << 32,
        Builtin.UnsupportedSysvar => 7 << 32,
        Builtin.IllegalOwner => 8 << 32,
        Builtin.MaxAccountsDataAllocationsExceeded => 9 << 32,
        Builtin.InvalidAccountDataRealloc => 10 << 32,
        Builtin.MaxInstructionTraceLengthExceeded => 11 << 32,
        Builtin.BuiltinProgramsMustConsumeComputeUnits => 12 << 32,
        Builtin.InvalidAccountOwner => 13 << 32,
        Builtin.ArithmeticOverflow => 14 << 32,
        Builtin.Immutable => 15 << 32,
        Builtin.IncorrectAuthority => 16 << 32,
    };
}
