pub const Pixel = struct {
    shape_colour: [3]u8,
    current_colour: ?[3]u8 = null,

    pub fn init(self: *Pixel, colour: [3]u8) *Pixel {
        self.current_colour = null;
        self.shape_colour = colour;
        return self;
    }
};
