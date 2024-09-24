pub fn Buffer(comptime T: type, comptime size: usize) type {
    return struct {
        const Self = @This();
        __buffer: [size]T = undefined,
        len: usize = 0,

        pub fn append(self: *Self, item: T) void {
            if (self.len < self.__buffer.len) {
                self.__buffer[self.len] = item;
                self.len += 1;
            } else unreachable;
        }

        pub fn appendUnique(self: *Self, item: T) void {
            if (!self.contains(item)) {
                self.append(item);
            }
        }

        pub fn iter(self: *Self) []T {
            return self.__buffer[0..self.len];
        }

        pub fn contains(self: *Self, item: T) bool {
            for (self.iter()) |v| {
                if (v == item) {
                    return true;
                }
            }
            return false;
        }
    };
}
