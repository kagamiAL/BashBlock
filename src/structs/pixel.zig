pub const Pixel = struct {
    shape_colour: ?[3]u8 = null,
    current_colour: ?[3]u8 = null,

    pub fn init(self: *Pixel) *Pixel {
        self.current_colour = null;
        self.shape_colour = null;
        return self;
    }
};
