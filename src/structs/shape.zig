const std = @import("std");
const all_shapes = @import("../data/all_shapes.zig").all_shapes;

const colors = [_][3]u8{
    .{ 0, 255, 255 },
    .{ 255, 255, 0 },
    .{ 128, 0, 128 },
    .{ 0, 255, 0 },
    .{ 255, 0, 0 },
    .{ 0, 0, 255 },
    .{ 255, 127, 0 },
};

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
    rand: *const std.Random,
    allocator: *const std.mem.Allocator,

    pub fn init(allocator: *const std.mem.Allocator, random: *const std.Random) Shape {
        return .{
            .allocator = allocator,
            .rand = random,
        };
    }

    pub fn randomize(self: *Shape) !void {
        const shape_offsets = all_shapes[self.rand.intRangeAtMost(usize, 0, all_shapes.len - 1)];
        const amt_rotates = self.rand.intRangeAtMost(usize, 1, 3);
        const offset_copy = try self.allocator.alloc(i8, shape_offsets.len);
        std.mem.copyForwards(i8, offset_copy, shape_offsets);
        rotateOffsetByAmt(offset_copy, amt_rotates);
        self.color = colors[self.rand.intRangeAtMost(usize, 0, colors.len - 1)];
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
