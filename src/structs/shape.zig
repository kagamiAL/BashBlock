const std = @import("std");

const left_shape = [_]i8{ 1, 0, -1, 0, 1, 1 };
const all_shapes = [_][]const i8{
    &left_shape,
};

pub const Shape = struct {
    offsets: []const i8 = undefined,
    color: [3]u8 = undefined,
    active: bool = false,

    pub fn randomize(self: *Shape, random: *const std.Random) void {
        self.color = [3]u8{
            random.intRangeAtMost(u8, 0, 255),
            random.intRangeAtMost(u8, 0, 255),
            random.intRangeAtMost(u8, 0, 255),
        };
        self.offsets = all_shapes[random.intRangeAtMost(usize, 0, all_shapes.len - 1)];
    }
};
