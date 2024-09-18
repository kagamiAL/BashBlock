const std = @import("std");
const vaxis = @import("vaxis");

const Game = @import("./structs/game.zig").Game;

const size_x = 19;
const size_y = 11;
const offset_x: comptime_int = size_x / 2;
const offset_y: comptime_int = size_y / 2;

var game_main = Game{};

/// Set the default panic handler to the vaxis panic_handler. This will clean up the terminal if any
/// panics occur
pub const panic = vaxis.panic_handler;

/// Set some scope levels for the vaxis scopes
pub const std_options: std.Options = .{
    .log_scope_levels = &.{
        .{ .scope = .vaxis, .level = .warn },
        .{ .scope = .vaxis_parser, .level = .warn },
    },
};

/// Tagged union of all events our application will handle. These can be generated by Vaxis or your
/// own custom events
const Event = union(enum) {
    key_press: vaxis.Key,
    key_release: vaxis.Key,
    focus_in, // window has gained focus
    focus_out, // window has lost focus
    paste_start, // bracketed paste start
    paste_end, // bracketed paste end
    paste: []const u8, // osc 52 paste, caller must free
    color_report: vaxis.Color.Report, // osc 4, 10, 11, 12 response
    color_scheme: vaxis.Color.Scheme, // light / dark OS theme changes
    winsize: vaxis.Winsize, // the window size has changed. This event is always sent when the loop
    // is started
};

/// The application state
const BashBlock = struct {
    allocator: std.mem.Allocator,
    // A flag for if we should quit
    should_quit: bool,
    /// The tty we are talking to
    tty: vaxis.Tty,
    /// The vaxis instance
    vx: vaxis.Vaxis,

    pub fn init(allocator: std.mem.Allocator) !BashBlock {
        return .{
            .allocator = allocator,
            .should_quit = false,
            .tty = try vaxis.Tty.init(),
            .vx = try vaxis.init(allocator, .{}),
        };
    }

    pub fn deinit(self: *BashBlock) void {
        // Deinit takes an optional allocator. You can choose to pass an allocator to clean up
        // memory, or pass null if your application is shutting down and let the OS clean up the
        // memory
        self.vx.deinit(self.allocator, self.tty.anyWriter());
        self.tty.deinit();
    }

    pub fn run(self: *BashBlock) !void {
        // Initialize our event loop. This particular loop requires intrusive init
        var loop: vaxis.Loop(Event) = .{
            .tty = &self.tty,
            .vaxis = &self.vx,
        };
        try loop.init();

        // Start the event loop. Events will now be queued
        try loop.start();
        defer loop.stop();

        try self.vx.enterAltScreen(self.tty.anyWriter());

        // Query the terminal to detect advanced features, such as kitty keyboard protocol, etc.
        // This will automatically enable the features in the screen you are in, so you will want to
        // call it after entering the alt screen if you are a full screen application. The second
        // arg is a timeout for the terminal to send responses. Typically the response will be very
        // fast, however it could be slow on ssh connections.
        try self.vx.queryTerminal(self.tty.anyWriter(), 1 * std.time.ns_per_s);

        // This is the main event loop. The basic structure is
        // 1. Handle events
        // 2. Draw application
        // 3. Render
        while (!self.should_quit) {
            // pollEvent blocks until we have an event
            loop.pollEvent();
            // tryEvent returns events until the queue is empty
            while (loop.tryEvent()) |event| {
                try self.update(event);
            }
            // Draw our application after handling events
            self.draw();

            // It's best to use a buffered writer for the render method. TTY provides one, but you
            // may use your own. The provided bufferedWriter has a buffer size of 4096
            var buffered = self.tty.bufferedWriter();
            // Render the application to the screen
            try self.vx.render(buffered.writer().any());
            try buffered.flush();
        }
    }

    /// Update our application state from an event
    pub fn update(self: *BashBlock, event: Event) !void {
        switch (event) {
            .key_press => |key| {
                // key.matches does some basic matching algorithms. Key matching can be complex in
                // the presence of kitty keyboard encodings, this will generally be a good approach.
                // There are other matching functions available for specific purposes, as well
                if (key.matches('c', .{ .ctrl = true }))
                    self.should_quit = true;
                switch (key.codepoint) {
                    13 => try game_main.placeShape(),
                    57350...57353 => game_main.moveShape(key.codepoint - 57350),
                    else => {},
                }
            },
            .winsize => |ws| try self.vx.resize(self.allocator, self.tty.anyWriter(), ws),
            else => {},
        }
    }

    /// Draw our current state
    pub fn draw(self: *BashBlock) void {
        // Window is a bounded area with a view to the screen. You cannot draw outside of a windows
        // bounds. They are light structures, not intended to be stored.
        const win = self.vx.window();

        // Clearing the window has the effect of setting each cell to it's "default" state. Vaxis
        // applications typically will be immediate mode, and you will redraw your entire
        // application during the draw cycle.
        win.clear();

        // In addition to clearing our window, we want to clear the mouse shape state since we may
        // be changing that as well
        self.vx.setMouseShape(.default);

        const main_display = win.child(.{
            .x_off = win.width / 2 - offset_x,
            .y_off = win.height / 2 - offset_y,
            .width = .{ .limit = size_x },
            .height = .{ .limit = size_y },
            .border = .{
                .where = .all,
                .glyphs = .single_square,
            },
        });
        game_main.drawBoardContents(&main_display);
    }
};

/// Keep our main function small. Typically handling arg parsing and initialization only
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) {
            std.log.err("memory leak", .{});
        }
    }
    const allocator = gpa.allocator();

    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    // Initialize our application
    var app = try BashBlock.init(allocator);
    defer app.deinit();

    try game_main.init(&allocator, &rand);
    defer game_main.deinit();

    // Run the application
    try app.run();
}
