const vaxis = @import("vaxis");
const std = @import("std");
const Allocator = std.mem.Allocator;

const Pixel = @import("./pixel.zig").Pixel;

const amt_cells = 9;

const default_color = [3]u8{ 255, 255, 255 };

pub const Game = struct {
    board: [amt_cells][amt_cells]?*Pixel = .{.{null} ** amt_cells} ** amt_cells,
    allocator: *const Allocator = undefined,

    pub fn hookAllocator(self: *Game, allocator: *const Allocator) void {
        self.allocator = allocator;
    }

    pub fn deinit(self: *Game) void {
        for (self.board) |row| {
            for (row) |value| {
                if (value) |pixel| {
                    self.allocator.destroy(pixel);
                }
            }
        }
    }

    pub fn drawBoardContents(self: *Game, display: *const vaxis.Window) void {
        for (0..amt_cells) |x| {
            for (0..amt_cells) |y| {
                var color: [3]u8 = undefined;
                var str: []const u8 = undefined;
                if (self.board[y][x]) |pixel| {
                    str = "■";
                    color = pixel.current_colour orelse pixel.shape_colour;
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
