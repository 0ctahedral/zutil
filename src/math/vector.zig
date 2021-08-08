const std = @import("std");
const expect = std.testing.expect;

pub fn vec(N: usize) type {
    return struct {
        //x: f32 = 0.0,
        //y: f32 = 0.0,
        //z: f32 = 0.0,

        data: [N]f32,

        const Self = @This();

        /// create a vector from a slice
        pub fn init(s: anytype) Self {
            //assert(s.len == N);
            return .{.data=s};
        }

        /// are the two vectors equal
        pub fn eql(a: Self, b: Self) callconv(.Inline) bool {
            return std.mem.eql(f32, &a.data, &b.data);
        }

//        /// add two vectors component-wise
//        pub fn add(a: Self, b: Self) callconv(.Inline) Self {
//            return .{
//                .x = a.x + b.x,
//                .y = a.y + b.y,
//                .z = a.z + b.z,
//            };
//        }
//
//        /// subtract two vectors component-wise
//        pub fn sub(a: Self, b: Self) callconv(.Inline) Self {
//            return .{
//                .x = a.x - b.x,
//                .y = a.y - b.y,
//                .z = a.z - b.z,
//            };
//        }
//
//        /// multiply two vectors component-wise, or by a scalar
//        pub fn mul(a: Self, b: anytype) callconv(.Inline) Self {
//            // if its a vector the n component-wise
//            // if scalar then
//            return switch (@TypeOf(b)) {
//                vec3 => .{
//                    .x = a.x * b.x,
//                    .y = a.y * b.y,
//                    .z = a.z * b.z,
//                },
//                f32 => .{
//                    .x = a.x * b,
//                    .y = a.y * b,
//                    .z = a.z * b,
//                },
//                else => @compileError("Only valid types are f32 and vec"),
//            };
//        }
    };
}

test "equal" {
    const a = vec(3).init(.{1.0, 2.0, 3.0});
    const b = vec(3).init(.{1.0, 2.0, 3.0});
    try expect(a.eql(b));
    try expect(b.eql(a));
    try expect(vec(3).eql(a, b));
}
//
//test "addition" {
//    const a = vec3{.x=1.0, .y=2.0, .z=-3.0};
//    const b = vec3{.x=1.0, .y=-2.0, .z=-3.0};
//    const c = vec3{.x=2.0, .y=0.0, .z=-6.0};
//
//    try expect(c.eql(a.add(b)));
//    try expect(c.eql(b.add(a)));
//}
//
//test "multiplication" {
//    const a = vec3{.x=1.0, .y=2.0, .z=3.0};
//    const b = vec3{.x=2.0, .y=4.0, .z=6.0};
//
//    try expect(b.eql(a.mul(@as(f32,2))));
//    try expect(vec3.eql(a.mul(b), .{ .x=2.0, .y=8.0, .z=18.0, }));
//}
