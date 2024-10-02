const vaxis = @import("vaxis");
const std = @import("std");
const Allocator = std.mem.Allocator;

const Pixel = @import("./pixel.zig").Pixel;
const Shape = @import("./shape.zig").Shape;
const Buffer = @import("../util/buffer.zig").Buffer;

const amt_cells = 9;
const prefix = "Score: ";
const default_color = [3]u8{ 255, 255, 255 };
const directions = [4][2]i8{
    [_]i8{ 0, -1 },
    [_]i8{ 0, 1 },
    [_]i8{ -1, 0 },
    [_]i8{ 1, 0 },
};

pub const Game = struct {
    const U8Buffer = Buffer(u8, max_num_width + 7);
    const USizeBuffer = Buffer(usize, 9);
    pub const max_num_width = 20;

    shapes: [3]Shape = undefined,
    board: [amt_cells][amt_cells]Pixel = .{.{Pixel{}} ** amt_cells} ** amt_cells,
    position: [2]i8 = .{ amt_cells / 2, amt_cells / 2 },
    score: usize = 0,
    score_display_buffer: U8Buffer = U8Buffer{},
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
        self.score_display_buffer.appendConst(prefix);
        self.score_display_buffer.append('0');
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
            if (self.num_scored > 0) {
                self.processScoredMatchingShapes();
                try self.updateScoreDisplayBuffer();
            }
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

    pub fn displayGameScore(self: *Game, display: *const vaxis.Window) !void {
        _ = try display.printSegment(.{
            .text = self.score_display_buffer.iter(),
        }, .{});
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
        var rows = USizeBuffer{};
        var columns = USizeBuffer{};
        var sqaures = USizeBuffer{};
        const selected_shape = &self.shapes[self.selected_index];
        var iterator = selected_shape.iterRelative(self.position);
        while (iterator.next()) |pos| {
            rows.appendUnique(pos[0]);
            columns.appendUnique(pos[1]);
            sqaures.appendUnique(Game.getSquareIndex(pos));
        }
        for (rows.iter()) |row| {
            if (self.checkRow(row)) {
                self.num_scored += 1;
            }
        }
        for (columns.iter()) |column| {
            if (self.checkColumn(column)) {
                self.num_scored += 1;
            }
        }
        for (sqaures.iter()) |square| {
            if (self.checkSquare(square)) {
                self.num_scored += 1;
            }
        }
    }

    fn checkRow(self: *Game, rowIndex: usize) bool {
        for (self.board[rowIndex]) |v| {
            if (v.shape_colour == null and v.current_colour == null) {
                return false;
            }
        }
        for (&self.board[rowIndex]) |*v| {
            v.markForRemoval(self.shapes[self.selected_index].color);
        }
        return true;
    }

    fn checkColumn(self: *Game, column_index: usize) bool {
        for (self.board) |row| {
            const pixel = row[column_index];
            if (pixel.shape_colour == null and pixel.current_colour == null) {
                return false;
            }
        }
        for (&self.board) |*row| {
            row[column_index].markForRemoval(self.shapes[self.selected_index].color);
        }
        return true;
    }

    fn checkSquare(self: *Game, square_number: usize) bool {
        var y: usize = square_number / 3;
        var x: usize = square_number - (3 * y);
        y *= 3;
        x *= 3;
        for (0..3) |y1| {
            for (0..3) |x1| {
                const pixel = self.board[y + y1][x + x1];
                if (pixel.current_colour == null and pixel.shape_colour == null) {
                    return false;
                }
            }
        }
        for (0..3) |y1| {
            for (0..3) |x1| {
                self.board[y + y1][x + x1].markForRemoval(self.shapes[self.selected_index].color);
            }
        }
        return true;
    }

    inline fn getSquareIndex(position: [2]usize) usize {
        const y: usize = position[0] / 3;
        const x: usize = position[1] / 3;
        return (y * 3) + x;
    }

    fn processScoredMatchingShapes(self: *Game) void {
        var amt_pixels: usize = 0;
        for (&self.board) |*arr| {
            for (arr) |*pixel| {
                if (pixel.marked) {
                    pixel.shape_colour = null;
                    amt_pixels += 1;
                }
            }
        }
        self.score += amt_pixels * self.num_scored;
    }

    fn updateScoreDisplayBuffer(self: *Game) !void {
        self.score_display_buffer.crop(7);
        var buf: [max_num_width]u8 = undefined;
        const num_str = try std.fmt.bufPrint(&buf, "{}", .{self.score});
        self.score_display_buffer.appendConst(num_str);
    }
};
