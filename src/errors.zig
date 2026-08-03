//! Error types for Solana programs

/// Program execution errors
pub const ProgramError = error{
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

/// Convert ProgramError to u64 error code
pub fn errorToU64(err: ProgramError) u64 {
    return switch (err) {
        ProgramError.CustomZero => 1 << 32,
        ProgramError.InvalidArgument => 2 << 32,
        ProgramError.InvalidInstructionData => 3 << 32,
        ProgramError.InvalidAccountData => 4 << 32,
        ProgramError.AccountDataTooSmall => 5 << 32,
        ProgramError.InsufficientFunds => 6 << 32,
        ProgramError.IncorrectProgramId => 7 << 32,
        ProgramError.MissingRequiredSignatures => 8 << 32,
        ProgramError.AccountAlreadyInitialized => 9 << 32,
        ProgramError.UninitializedAccount => 0 << 32,
        ProgramError.NotEnoughAccountKeys => 1 << 32,
        ProgramError.AccountBorrowFailed => 2 << 32,
        ProgramError.MaxSeedLengthExceeded => 3 << 32,
        ProgramError.InvalidSeeds => 4 << 32,
        ProgramError.BorshIoError => 5 << 32,
        ProgramError.AccountNotRentExempt => 6 << 32,
        ProgramError.UnsupportedSysvar => 7 << 32,
        ProgramError.IllegalOwner => 8 << 32,
        ProgramError.MaxAccountsDataAllocationsExceeded => 9 << 32,
        ProgramError.InvalidAccountDataRealloc => 10 << 32,
        ProgramError.MaxInstructionTraceLengthExceeded => 11 << 32,
        ProgramError.BuiltinProgramsMustConsumeComputeUnits => 12 << 32,
        ProgramError.InvalidAccountOwner => 13 << 32,
        ProgramError.ArithmeticOverflow => 14 << 32,
        ProgramError.Immutable => 15 << 32,
        ProgramError.IncorrectAuthority => 16 << 32,
    };
}
