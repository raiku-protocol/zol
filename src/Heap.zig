// The simplest and cheapest heap allocation imaginable.
// Caller is responsible for keeping only one instance live at a time.

pub const std = @import("std");
pub const Heap = @This();

bump: u64 = @import("constants.zig").heap_start,

pub fn alloc(self: *Heap, T: type, len: usize) []T {
    const bump_aligned = alignTo(@alignOf(T), self.bump);
    const slice_start: [*]T = @ptrFromInt(bump_aligned);
    self.bump = bump_aligned + len * @sizeOf(T);
    return slice_start[0..len];
}

// Scratch buffer, memory is invalidated and thus 'freed' at end of lifetime
//
// Caller is responsible for keeping only one scratch alive at a time.
pub fn scratch(self: Heap) Heap {
    return .{
        .bump = self.bump,
    };
}

pub fn alignTo(alignment: usize, offset: usize) usize {
    const off = offset % alignment;
    return if (off == 0) return offset else return offset + alignment - off;
}
