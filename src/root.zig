const errors = @import("errors.zig");
const types = @import("types.zig");
const syscalls = @import("syscalls.zig");

const log = @import("log.zig");
const entrypoint = @import("entrypoint.zig");
const pda = @import("pda.zig");
const cpi = @import("cpi.zig");
pub const debug = @import("debug.zig").debug;

pub const BuiltinError = errors.Builtin;
pub const errorToU64 = errors.errorToU64;

pub const Pubkey = types.Pubkey;
pub const Account = types.Account;

pub const pubkeyEq = types.pubkeyEq;
pub const parseArgs = entrypoint.parseArgs;
pub const Args = entrypoint.Args;

pub const logPubkey = log.logPubkey;
pub const logMsg = log.log;
pub const logU64 = log.logU64;
pub const logComputeUnits = log.logComputeUnits;
pub const getRemainingComputeUnits = log.getRemainingComputeUnits;

pub const findProgramAddress = pda.findProgramAddress;
pub const createProgramAddress = pda.createProgramAddress;
pub const createWithSeed = pda.createWithSeed;

pub const AccountMeta = cpi.AccountMeta;
pub const Instruction = cpi.Instruction;
pub const invoke = cpi.invoke;
pub const invokeSigned = cpi.invokeSigned;
pub const setReturnData = cpi.setReturnData;
pub const getReturnData = cpi.getReturnData;

pub const MAX_SEEDS = pda.MAX_SEEDS;
pub const MAX_SEED_LEN = pda.MAX_SEED_LEN;
pub const MAX_TX_ACCOUNTS = types.MAX_TX_ACCOUNTS;
pub const NON_DUP_MARKER = types.NON_DUP_MARKER;
pub const MAX_PERMITTED_DATA_INCREASE = types.MAX_PERMITTED_DATA_INCREASE;

test {
    _ = debug;
}
