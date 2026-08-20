//! Core Solana types
const std = @import("std");
const base58 = @import("base58");
const abi = @import("abi.zig");

const ProgramError = @import("errors.zig").ProgramError;

/// Public key type
pub const Pubkey = extern struct {
    bytes: [32]u8 align(8),

    pub fn eq(a: *const @This(), b: *const @This()) bool {
        return std.mem.eql(u8, &a.bytes, &b.bytes);
    }

    pub fn b58(comptime str: []const u8) @This() {
        return parse(str) catch {
            @compileError("Invalid encoding");
        };
    }

    pub fn parse(bytes: []const u8) !@This() {
        var buf: [32]u8 = undefined;
        const slice = try base58.decode32(&buf, bytes);
        if (slice.len != buf.len) return error.InvalidPubkey;
        return .{ .bytes = buf };
    }
};

pub const Permissions = struct {
    writable: bool = false,
    signer: bool = false,
};

// The extern qualifier guarantes ABI compatability with AccountInfo
pub const Account = extern struct {
    inner: abi.AccountInfo,

    pub fn restrict(self: Account, permissions: Permissions) Account {
        var copy = self.inner;
        copy.writable = if (permissions.writable) 1 else 0;
        copy.signer = if (permissions.signer) 1 else 0;
        return .{ .inner = copy };
    }

    pub fn lamports(self: Account) *u64 {
        return self.inner.lamports;
    }

    pub fn owner(self: Account) *const Pubkey {
        return self.inner.owner;
    }

    pub fn address(self: Account) *const Pubkey {
        return self.inner.address;
    }

    pub fn data(self: Account) []u8 {
        return self.inner.data[0..self.inner.data_len];
    }

    pub fn signer(self: Account) bool {
        return self.inner.signer != 0;
    }

    pub fn writable(self: Account) bool {
        return self.inner.writable != 0;
    }

    pub fn executable(self: Account) bool {
        return self.inner.executable != 0;
    }
};
