const std = @import("std");
const Allocator = std.mem.Allocator;
const expect = std.testing.expect;

/// Create a new shared pointer 'factory' of type T
pub fn Ref(comptime T: type) type {

    // The acutal shared part of the pointer
    const Ptr = struct {
        /// value of this shared pointer
        val: T,
        /// number of strong references to this pointer
        count: usize,
    };

    // Returns a strong reference to the inner value
    return struct {
        const Self = @This();

        /// pointer to the reference counted value
        inner: *Ptr,

        /// allocates a new strong reference given the value v
        fn new(allocator: *Allocator, v: T) !Self {
            // allocate the inner
            const n_inner = try allocator.create(Ptr);
            n_inner.* = Ptr{
                .val = v,
                .count = 1,
            };

            return Self{
                .inner = n_inner,
            };
        }

        /// Destroy the allocated inner counter and value
        /// if this is the only reference.
        /// Otherwise, we just decrement the counter
        fn deinit(self: Self, allocator: *Allocator) void {
            const c = dec(self.inner);
            if (c == 1) {
                allocator.destroy(self.inner);
            }
        }

        /// create a new strong reference to the value shared in here
        fn clone(self: Self) Self {
            _ = inc(self.inner);
            return Self{
                .inner = self.inner,
            };
        }

        /// returns a const pointer to the value stored in this Ref
        fn ptr(self: *Self) *const T {
            return &self.inner.*.val;
        }

        /// returns an unsafe, mutable pointer to this value.
        /// this should only be used if there is one owner of
        /// this reference
        fn rawPtr(self: *Self) *T {
            return &self.inner.*.val;
        }

        /// Get the number of references to this data
        inline fn count(self: Self) usize {
            return @atomicLoad(usize, &self.inner.*.count, .SeqCst);
        }

        /// increase the pointer count and return the previous value
        inline fn inc(p: *Ptr) usize {
            // load the value
            var v = @atomicLoad(usize, &p.*.count, .Acquire);
            // compare to see if the value has changed since loading
            while (@cmpxchgWeak(usize, &p.*.count, v, v + 1, .Release, .Monotonic)) |nv| {
                v = nv;
            }
            return v;
        }

        /// decrease the pointer count and return the previous value
        inline fn dec(p: *Ptr) usize {
            var v = @atomicLoad(usize, &p.*.count, .Acquire);
            // compare to see if the value has changed since loading
            while (@cmpxchgWeak(usize, &p.*.count, v, if (v == 0) v else v - 1, .Release, .Monotonic)) |nv| {
                v = nv;
            }
            return v;
        }
    };
}

test "init" {
    const allocator = std.testing.allocator;
    const p = try Ref(u8).new(allocator, 5);
    defer p.deinit(allocator);

    // test that the count is 1
    try expect(p.inner.*.count == 1);
}

test "clone and deinit" {
    const allocator = std.testing.allocator;
    const p = try Ref(u8).new(allocator, 5);
    defer p.deinit(allocator);

    try expect(p.inner.*.count == 1);

    var p2 = p.clone();
    // check count
    try expect(p.inner.*.count == 2);
    try expect(p2.inner.*.count == 2);
    try expect(p2.inner.*.val == 5);
    try expect(p.inner.*.val == 5);

    p2.deinit(allocator);

    // the count should now b 1
    try expect(p.inner.*.count == 1);
}

test "count" {
    const allocator = std.testing.allocator;
    const p = try Ref(u8).new(allocator, 5);
    defer p.deinit(allocator);

    try expect(p.inner.*.count == p.count());
    try expect(p.count() == 1);
}
