// FIXME: handle alignment properly
// The simplest and cheapest heap allocation imaginable.
// Caller is responsible for keeping only one instance live at a time.

pub const std = @import("std");
pub const Heap = @This();

bump: u64 = @import("constants.zig").heap_start,

pub fn alloc(self: *Heap, T: type, len: usize) []T {
    const slice_start: [*]T = @ptrFromInt(self.bump);
    self.bump += len * @sizeOf(T);
    return slice_start[0..len];
}

pub fn create(self: *Heap, T: type, t: T) *T {
    const item = &self.alloc(T, 1)[0];
    item.* = t;
    return item;
}

pub fn dupe(self: *Heap, T: type, slice: []const T) []T {
    const duped = self.alloc(T, slice.len);
    std.mem.copyForwards(T, duped, slice);
    return duped;
}

// TODO: add debug verification
pub fn free(self: *Heap, T: type, slice: []T) void {
    self.bump = @intFromPtr(slice.ptr);
}

// Scratch buffer, memory is invalidated and thus 'freed' at end of lifetime
//
// Caller is responsible for keeping only one scratch alive at a time.
pub fn scratch(self: Heap) Heap {
    return .{
        .bump = self.bump,
    };
}
