const std = @import("std");
const all_shapes = @import("../data/all_shapes.zig").all_shapes;

fn rotateOffsetByAmt(offsets: []i8, amt: usize) void {
    var i: usize = 0;
    while (i < offsets.len - 1) : (i += 2) {
        for (0..amt) |_| {
            const y = offsets[i + 1];
            offsets[i + 1] = -offsets[i];
            offsets[i] = y;
        }
    }
}

pub const Shape = struct {
    offsets: []const i8 = undefined,
    color: [3]u8 = undefined,
    active: bool = false,

    pub fn randomize(self: *Shape, allocator: *const std.mem.Allocator, random: *const std.Random) !void {
        const shape_offsets = all_shapes[random.intRangeAtMost(usize, 0, all_shapes.len - 1)];
        const amt_rotates = random.intRangeAtMost(usize, 1, 3);
        const offset_copy = try allocator.alloc(i8, shape_offsets.len);
        std.mem.copyForwards(i8, offset_copy, shape_offsets);
        rotateOffsetByAmt(offset_copy, amt_rotates);
        self.color = [3]u8{
            random.intRangeAtMost(u8, 50, 255),
            random.intRangeAtMost(u8, 50, 255),
            random.intRangeAtMost(u8, 50, 255),
        };
        self.offsets = offset_copy;
    }

    pub fn inBounds(self: *Shape, y: i8, x: i8) bool {
        var i: usize = 0;
        while (i < self.offsets.len - 1) : (i += 2) {
            const y2 = y + self.offsets[i];
            const x2 = x + self.offsets[i + 1];
            if (y2 < 0 or y2 >= 9 or x2 < 0 or x2 >= 9) {
                return false;
            }
        }
        return true;
    }
};
