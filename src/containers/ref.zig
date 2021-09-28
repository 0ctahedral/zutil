const std = @import("std");
const Allocator = std.mem.Allocator;

/// Create a new shared pointer 'factory' of type T
pub fn Ref(comptime T: type) type {

    // The acutal shared part of the pointer
    const Ptr = struct {
        /// value of this shared pointer
        val: T,
        /// number of strong references to this pointer
        count: usize,

        /// increase the pointer count
        inline fn inc(ptr: *Ptr) void {
            // load the value
            var v = @atomicLoad(usize, &ptr.*.count, .Aquire);
            // compare to see if the value has changed since loading
            while (@cmpxchgWeak(usize, &ptr.*.count, v + 1, .Release, .Monotonic)) |nv| {
                v = nv;
            }
        }

        /// decrease the pointer count
        inline fn dec(ptr: *Ptr) void {
            var v = @atomicLoad(usize, &ptr.*.count, .Aquire);
            // compare to see if the value has changed since loading
            while (@cmpxchgWeak(usize, &ptr.*.count, if (v == 0) v else v - 1, .Release, .Monotonic)) |nv| {
                v = nv;
            }
        }
    };

    // Returns a strong reference to the inner value
    return struct {
        const Self = @This();

        /// pointer to the reference counted value
        inner: *Ptr,

        /// allocates a new strong reference given the value v
        pub fn new(allocator: *Allocator, v: T) !Self {
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
        pub fn deinit(self: *Self, allocator: *Allocator) void {
            allocator.destroy(self.inner);
        }

        /// create a new strong reference to the value shared in here
        pub fn clone(self: *Self) !Self {
            self.inner.inc();
            return Self{
                .inner = self.inner,
            };
        }

        /// returns a const pointer to the value stored in this Ref
        pub fn ptr(self: *Self) *const T {
            return &self.inner.*.val;
        }

        /// returns an unsafe, mutable pointer to this value.
        /// this should only be used if there is one owner of
        /// this reference
        pub fn rawPtr(self: *Self) *T {
            return &self.inner.*.val;
        }
    };
}

test "init" {
    const allocator = std.testing.allocator;
    var p = try Ref(u8).new(allocator, 5);
    defer p.deinit(allocator);
}
