pub const Pixel = struct {
    shape_colour: ?[3]u8 = null,
    current_colour: ?[3]u8 = null,
    marked: bool = false,

    pub fn init(self: *Pixel) *Pixel {
        self.current_colour = null;
        self.shape_colour = null;
        return self;
    }

    pub fn resetTemp(self: *Pixel) void {
        self.current_colour = null;
        self.marked = false;
    }

    pub fn markForRemoval(self: *Pixel, color: [3]u8) void {
        self.current_colour = color;
        self.marked = true;
    }
};
