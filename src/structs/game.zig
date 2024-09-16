const vaxis = @import("vaxis");
const std = @import("std");
const Allocator = std.mem.Allocator;

const Pixel = @import("./pixel.zig").Pixel;
const Shape = @import("./shape.zig").Shape;

const amt_cells = 9;
const default_color = [3]u8{ 255, 255, 255 };

pub const Game = struct {
    shapes: [3]Shape = .{Shape{}} ** 3,
    board: [amt_cells][amt_cells]Pixel = .{.{Pixel{}} ** amt_cells} ** amt_cells,
    allocator: *const Allocator = undefined,
    rand: *const std.Random = undefined,

    pub fn init(self: *Game, allocator: *const Allocator, random: *const std.Random) void {
        self.allocator = allocator;
        self.rand = random;
        for (&self.shapes) |*shape| {
            shape.randomize(random);
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
};
