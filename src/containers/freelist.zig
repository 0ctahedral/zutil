//! wixed child of a linked list and array
//! each free slot contains a pointer to the next free slot
//![idea from here](https://blog.molecular-matters.com/2012/09/17/memory-allocation-strategies-a-pool-allocator/)
const std = @import("std");
const expect = std.testing.expect;

/// Creates a type of FreeList
pub fn FreeList(
    /// Type to return
    comptime T: type,
) type {
    return struct {
        const Self = @This();

        /// pointer to the next item in the linked list
        next: ?[*]Self = null,

        pub fn init(
            pool:[]align(8) u8,
            chunk_size: usize,
            //alignment: usize,
            //offset: usize,
        ) *Self {
            // clear the pool
            @memset(pool.ptr, 0, pool.len);

            var ret: *Self = @ptrCast(*Self, pool.ptr);
            ret.next = ret;
            ret += chunk_size;

            var runner: *Self = ret.next;
            //// number of items to make
            var i: usize = 0;
            while (i < n_items) : (i+=1) {
                runner.*.next = ret;
                runner = ret;
                ret += chunk_size;

            }
            runner.*.next = null;
            return ret;
        }
    };
}

test "inst" {
    var block: [1024]u8 align(8) = undefined;
   // var fl = FreeList(u32).init(block[0..], 32);

   // // pointing to the same place
   // try expect(@ptrToInt(fl) == @ptrToInt(&block[0]));
}
