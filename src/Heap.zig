// FIXME: handle alignment properly
// The simplest and cheapest heap allocation imaginable.
// Caller is responsible for keeping only one instance live at a time.

bump: u64 = @import("constants.zig").heap_start,

pub const Heap = @This();

pub fn alloc(self: *Heap, T: type, len: usize) []T {
    const slice_start: [*]T = @ptrFromInt(self.bump);
    self.bump += len * @sizeOf(T);
    return slice_start[0..len];
}
