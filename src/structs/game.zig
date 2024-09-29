const vaxis = @import("vaxis");
const std = @import("std");
const Allocator = std.mem.Allocator;

const Pixel = @import("./pixel.zig").Pixel;
const Shape = @import("./shape.zig").Shape;
const Buffer = @import("../util/buffer.zig").Buffer(usize, 9);

const amt_cells = 9;
const default_color = [3]u8{ 255, 255, 255 };
const directions = [4][2]i8{
    [_]i8{ 0, -1 },
    [_]i8{ 0, 1 },
    [_]i8{ -1, 0 },
    [_]i8{ 1, 0 },
};

pub const Game = struct {
    shapes: [3]Shape = undefined,
    board: [amt_cells][amt_cells]Pixel = .{.{Pixel{}} ** amt_cells} ** amt_cells,
    position: [2]i8 = .{ amt_cells / 2, amt_cells / 2 },
    selected_index: usize = 0,
    num_scored: usize = 0,
    allocator: *const Allocator = undefined,
    rand: *const std.Random = undefined,

    pub fn init(self: *Game, allocator: *const Allocator, random: *const std.Random) !void {
        self.allocator = allocator;
        self.rand = random;
        for (0..3) |i| {
            self.shapes[i] = Shape.init(allocator, random);
            try self.shapes[i].randomize();
        }
        self.tempColorCurrentShape(&self.shapes[self.selected_index]);
    }

    pub fn deinit(self: *Game) void {
        for (&self.shapes) |*shape| {
            self.allocator.free(shape.offsets);
        }
    }

    pub fn moveShape(self: *Game, index: usize) void {
        const move_direction = directions[index];
        const selected_shape = &self.shapes[self.selected_index];
        if (selected_shape.inBounds(self.position[0] + move_direction[0], self.position[1] + move_direction[1])) {
            self.clearBoardTemp();
            self.position[0] += move_direction[0];
            self.position[1] += move_direction[1];
            self.tempColorCurrentShape(selected_shape);
            self.highlightPotentialMatches();
        }
    }

    pub fn getNextAvailableShapeIndex(self: *Game) !usize {
        var i: usize = @mod(self.selected_index + 1, self.shapes.len);
        while (i != self.selected_index) : (i = @mod(i + 1, self.shapes.len)) {
            if (self.shapes[i].active) {
                return i;
            }
        }
        if (self.shapes[self.selected_index].active) {
            return self.selected_index;
        }
        //No more shapes, randomize
        for (&self.shapes) |*shape| {
            self.allocator.free(shape.offsets);
            try shape.randomize();
        }
        return 0;
    }

    pub fn placeShape(self: *Game) !void {
        const selected_shape = &self.shapes[self.selected_index];
        if (!self.shapeCollidesWithOtherShapes(selected_shape)) {
            var iter = self.shapes[self.selected_index].iterRelative(self.position);
            while (iter.next()) |position| {
                self.board[position[0]][position[1]].shape_colour = selected_shape.color;
            }
            selected_shape.active = false;
            self.processScoredMatchingShapes();
            try self.switchSelectedShape();
        }
    }

    pub fn switchSelectedShape(self: *Game) !void {
        self.selected_index = try self.getNextAvailableShapeIndex();
        self.position = .{ amt_cells / 2, amt_cells / 2 };
        self.clearBoardTemp();
        self.tempColorCurrentShape(&self.shapes[self.selected_index]);
        self.highlightPotentialMatches();
    }

    pub fn drawBoardContents(self: *Game, display: *const vaxis.Window) void {
        for (0..amt_cells) |x| {
            for (0..amt_cells) |y| {
                var color: [3]u8 = undefined;
                var str: []const u8 = undefined;
                const pixel = self.board[y][x];
                if (pixel.current_colour != null or pixel.shape_colour != null) {
                    str = "■";
                    color = pixel.current_colour orelse pixel.shape_colour.?;
                } else {
                    str = "□";
                    color = default_color;
                }
                const opts = vaxis.Window.ChildOptions{
                    .x_off = (x * 2),
                    .y_off = y,
                    .width = .{ .limit = 1 },
                    .height = .{ .limit = 1 },
                };
                const child = display.child(opts);
                child.writeCell(0, 0, .{
                    .char = .{
                        .grapheme = str,
                        .width = 1,
                    },
                    .style = .{
                        .fg = .{ .rgb = color },
                    },
                });
            }
        }
    }

    fn tempColorCurrentShape(self: *Game, shape: *const Shape) void {
        var iter = shape.iterRelative(self.position);
        while (iter.next()) |vector2| {
            self.board[vector2[0]][vector2[1]].current_colour = default_color;
        }
    }

    fn clearBoardTemp(self: *Game) void {
        self.num_scored = 0;
        for (&self.board) |*arr| {
            for (arr) |*pixel| {
                pixel.resetTemp();
            }
        }
    }

    fn shapeCollidesWithOtherShapes(self: *Game, shape: *const Shape) bool {
        var iter = shape.iterRelative(self.position);
        while (iter.next()) |vector2| {
            if (self.board[vector2[0]][vector2[1]].shape_colour != null) {
                return true;
            }
        }
        return false;
    }

    fn highlightPotentialMatches(self: *Game) void {
        if (self.shapeCollidesWithOtherShapes(&self.shapes[self.selected_index])) {
            return;
        }
        //These are to know what to check
        var rows = Buffer{};
        var columns = Buffer{};
        var sqaures = Buffer{};
        const selected_shape = &self.shapes[self.selected_index];
        var iterator = selected_shape.iterRelative(self.position);
        while (iterator.next()) |pos| {
            rows.appendUnique(pos[0]);
            columns.appendUnique(pos[1]);
            sqaures.appendUnique(Game.getSquareIndex(pos));
        }
    }

    fn getSquareIndex(position: [2]usize) usize {
        const y: usize = position[0] / 3;
        const x: usize = position[1] / 3;
        return (y * 3) + x;
    }

    fn processScoredMatchingShapes(self: *Game) void {
        for (&self.board) |*arr| {
            for (arr) |*pixel| {
                if (pixel.marked) {
                    pixel.shape_colour = null;
                }
            }
        }
    }
};
