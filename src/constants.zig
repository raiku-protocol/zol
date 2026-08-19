const types = @import("types.zig");

pub const system_program_id = types.Pubkey.b58("11111111111111111111111111111111");
pub const ata_program_id = types.Pubkey.b58("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL");
pub const spl_token_program_id = types.Pubkey.b58("TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA");
pub const spl_token_2022_program_id = types.Pubkey.b58("TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb");

pub const growth_buffer_size = 10 * 1024;
