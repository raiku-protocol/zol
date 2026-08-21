//! Core Solana types
const std = @import("std");
const base58 = @import("base58");
const abi = @import("abi.zig");
const Heap = @import("Heap.zig");

const ProgramError = @import("errors.zig").ProgramError;

/// Public key type
/// using packed representation to allow inclusion in packed structs
pub const Pubkey = packed struct {
    a: u64,
    b: u64,
    c: u64,
    d: u64,

    pub fn eq(self: *const @This(), other: *const @This()) bool {
        return true and
            self.a == other.a and
            self.b == other.b and
            self.c == other.c and
            self.d == other.d;
    }

    pub fn as_bytes(self: *const @This()) *const [32]u8 {
        const ptr: [*]const u8 = @ptrCast(self);
        return ptr[0..32];
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
        return Pubkey.from_bytes(buf);
    }

    pub fn from_bytes(bytes: [32]u8) @This() {
        return .{
            .a = std.mem.readInt(u64, bytes[0..8], .little),
            .b = std.mem.readInt(u64, bytes[8..16], .little),
            .c = std.mem.readInt(u64, bytes[16..24], .little),
            .d = std.mem.readInt(u64, bytes[24..32], .little),
        };
    }
};

pub const Permissions = struct {
    writable: bool = false,
    signer: bool = false,
};

pub const Account = struct {
    inner: *abi.Account,
    // Slice pointing to data + the 10kibi buffer for growing.
    backing_buffer: []align(8) u8,
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
        return Pubkey.from_bytes(self.inner.owner);
    }

    pub fn owned_by(self: Account, other: Pubkey) bool {
        return std.mem.eql(u8, other.as_bytes(), &self.inner.owner);
    }

    pub fn address(self: Account) Pubkey {
        return Pubkey.from_bytes(self.inner.address);
    }

    pub fn data(self: Account) []align(8) u8 {
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
