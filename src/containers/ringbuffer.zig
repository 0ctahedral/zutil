const std = @import("std");
const testing = std.testing;

pub fn Ringbuffer(
    comptime T: type,
    comptime capacity: usize,
) type {
    return struct {

        /// The maximum number of items this ringbuffer can hold
        capacity: usize = capacity,
        /// How many items are currently in the buffer
        len: usize = 0,

        /// The items in this ring buffer
        /// dot not access directly
        buffer: [capacity]T = undefined,

        const Self = @This();

        /// creates a new ringbuffer
        pub fn init() Self {
            return .{};
        }

        /// destroys the ringbuffer (not needed at the moment)
        pub fn deinit(self: Self) void {

        }

        /// add a new item to the ringbuffer
        pub fn push(self: *Self, item: T) !void {
            if (self.len == self.capacity)
                return error.BufferFull;
        }

        /// remove an item from the ringbuffer
        pub fn pop(self: *Self) ?T {
            if (self.len == 0)
                return null;

            return null;
        }
    };
}

test "ringbuffer init" {
    var rb = Ringbuffer(u8, 10).init();
    defer rb.deinit();

    // check that data is the same size
    try testing.expect(rb.buffer.len == rb.capacity);
    
    // check that 
    try testing.expect(rb.len == 0);
}

test "push pop" {
    var rb = Ringbuffer(u8, 10).init();
    defer rb.deinit();

    try testing.expect(rb.pop() == null);
}
