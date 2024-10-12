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
    .{ 206, 60, 174 },
};

/// rotate offsets by amt (there's probably a better way of doing this, but this works)
inline fn rotateOffsetByAmt(offsets: []i8, amt: usize) void {
    if (amt == 0) {
        return;
    }
    var i: usize = 0;
    while (i < offsets.len - 1) : (i += 2) {
        for (0..amt) |_| {
            const y = offsets[i + 1];
            offsets[i + 1] = -offsets[i];
            offsets[i] = y;
        }
    }
}

/// Iterator for relative offsets in a shape based on the current position
const ShapeIteratorRelative = struct {
    offsets: []const i8,
    position: [2]i8,
    i: usize = 0,

    pub fn init(offsets: []const i8, position: [2]i8) ShapeIteratorRelative {
        return .{ .offsets = offsets, .position = position };
    }

    pub fn next(self: *ShapeIteratorRelative) ?[2]usize {
        if (self.i < self.offsets.len - 1) {
            const y: usize = @intCast(self.position[0] + self.offsets[self.i]);
            const x: usize = @intCast(self.position[1] + self.offsets[self.i + 1]);
            self.i += 2;
            return .{ y, x };
        }
        return null;
    }
};

pub const Shape = struct {
    offsets: []const i8 = undefined,
    color: [3]u8 = undefined,
    active: bool = true,
    rand: *const std.Random,
    allocator: *const std.mem.Allocator,

    pub fn init(allocator: *const std.mem.Allocator, random: *const std.Random) Shape {
        return .{
            .allocator = allocator,
            .rand = random,
        };
    }

    /// Randomize the shape and set its color
    pub fn randomize(self: *Shape) !void {
        const shape_offsets = all_shapes[self.rand.intRangeAtMost(usize, 0, all_shapes.len - 1)];
        const amt_rotates = self.rand.intRangeAtMost(usize, 0, 3);
        const offset_copy = try self.allocator.alloc(i8, shape_offsets.len);
        std.mem.copyForwards(i8, offset_copy, shape_offsets);
        rotateOffsetByAmt(offset_copy, amt_rotates);
        self.active = true;
        self.color = colors[self.rand.intRangeAtMost(usize, 0, colors.len - 1)];
        self.offsets = offset_copy;
    }

    /// Check if the shape is in bounds
    pub inline fn inBounds(self: *Shape, y: i8, x: i8) bool {
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

    /// Get an iterator for the shape based on the current position
    pub fn iterRelative(self: *const Shape, position: [2]i8) ShapeIteratorRelative {
        return ShapeIteratorRelative.init(
            self.offsets,
            position,
        );
    }
};
