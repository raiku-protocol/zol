const Pubkey = @import("../types.zig").Pubkey;

pub const AccountData = packed struct {
    /// The mint associated with this account
    mint: Pubkey,

    /// The owner of this account.
    owner: Pubkey,

    /// The amount of tokens this account holds.
    amount: u64,

    /// Indicates whether the delegate is present or not.
    delegate_flag: u32,

    /// If `delegate` is `Some` then `delegated_amount` represents
    /// the amount authorized by the delegate.
    delegate: Pubkey,

    /// The account's state.
    state: u8,

    /// Indicates whether this account represents a native token or not.
    is_native: u32,

    /// When `is_native.is_some()` is `true`, this is a native token, and the
    /// value logs the rent-exempt reserve. An Account is required to be
    /// rent-exempt, so the value is used by the Processor to ensure that
    /// wrapped SOL accounts do not drop below this threshold.
    native_amount: u64,

    /// The amount delegated.
    delegated_amount: u64,

    /// Indicates whether the close authority is present or not.
    close_authority_flag: u32,

    /// Optional authority to close the account.
    close_authority: Pubkey,
};
