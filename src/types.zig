//! Core Solana types
const std = @import("std");
const base58 = @import("base58");
const abi = @import("abi.zig");
const Heap = @import("Heap.zig");

const ProgramError = @import("errors.zig").ProgramError;

/// Public key type
pub const Pubkey = extern struct {
    bytes: [32]u8,

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

pub const Account = struct {
    inner: *abi.Account,
    // Slice pointing to data + the 10kibi buffer for growing.
    backing_buffer: []u8,
    permissions: Permissions,

    pub fn with_permissions(self: Account, permissions: Permissions) Account {
        return .{
            .inner = self.inner,
            .backing_buffer = self.backing_buffer,
            .permissions = permissions,
        };
    }

    pub fn lamports(self: Account) u64 {
        return self.inner.lamports;
    }

    pub fn owner(self: Account) Pubkey {
        return self.inner.owner;
    }

    pub fn address(self: Account) Pubkey {
        return self.inner.address;
    }

    pub fn data(self: Account) []u8 {
        return self.backing_buffer[0..self.inner.data_len];
    }

    pub fn is_signer(self: Account) bool {
        return self.inner.signer != 0;
    }

    pub fn is_writable(self: Account) bool {
        return self.inner.writable != 0;
    }

    pub fn is_executable(self: Account) bool {
        return self.inner.executable != 0;
    }

    pub fn abi_info(self: Account) abi.AccountInfo {
        return .{
            .address = &self.inner.address,
            .lamports = &self.inner.lamports,
            .data = self.backing_buffer.ptr,
            .data_len = self.inner.data_len,
            .owner = &self.inner.owner,
            .signer = self.inner.signer,
            .writable = self.inner.writable,
            .executable = self.inner.executable,
        };
    }
};

// Abi compatible
pub const Seed = extern struct {
    inner: abi.SignerSeedC,

    pub fn init(seed: []const u8) Seed {
        return .{ .inner = .{ .addr = @intFromPtr(seed.ptr), .len = seed.len } };
    }
};

// Abi compatible
pub const Signer = extern struct {
    inner: abi.SignerSeedsC,

    pub fn init(seeds: []const Seed) Signer {
        return .{ .inner = .{ .addr = @intFromPtr(seeds.ptr), .len = seeds.len } };
    }
};
