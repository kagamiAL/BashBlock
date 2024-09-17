const vaxis = @import("vaxis");
const std = @import("std");
const Allocator = std.mem.Allocator;

const Pixel = @import("./pixel.zig").Pixel;
const Shape = @import("./shape.zig").Shape;

const amt_cells = 9;
const default_color = [3]u8{ 255, 255, 255 };
const directions = [4][2]i8{
    [_]i8{ 0, -1 },
    [_]i8{ 0, 1 },
    [_]i8{ -1, 0 },
    [_]i8{ 1, 0 },
};

pub const Game = struct {
    shapes: [3]Shape = .{Shape{}} ** 3,
    board: [amt_cells][amt_cells]Pixel = .{.{Pixel{}} ** amt_cells} ** amt_cells,
    position: [2]i8 = .{ amt_cells / 2, amt_cells / 2 },
    selected_shape: *Shape = undefined,
    allocator: *const Allocator = undefined,
    rand: *const std.Random = undefined,

    pub fn init(self: *Game, allocator: *const Allocator, random: *const std.Random) void {
        self.allocator = allocator;
        self.rand = random;
        self.selected_shape = &self.shapes[0];
        for (&self.shapes) |*shape| {
            shape.randomize(random);
            shape.active = true;
        }
        self.tempColorCurrentShape(self.selected_shape);
    }

    pub fn moveShape(self: *Game, index: usize) void {
        const move_direction = directions[index];
        if (self.selected_shape.inBounds(self.position[0] + move_direction[0], self.position[1] + move_direction[1])) {
            self.clearBoardTemp();
            self.position[0] += move_direction[0];
            self.position[1] += move_direction[1];
            self.tempColorCurrentShape(self.selected_shape);
        }
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
        var i: usize = 0;
        while (i < shape.offsets.len - 1) : (i += 2) {
            const y: usize = @intCast(self.position[0] + shape.offsets[i]);
            const x: usize = @intCast(self.position[1] + shape.offsets[i + 1]);
            self.board[y][x].current_colour = shape.color;
        }
    }

    fn clearBoardTemp(self: *Game) void {
        for (&self.board) |*arr| {
            for (arr) |*pixel| {
                pixel.current_colour = null;
            }
        }
    }
};
