BashBlock
========

BashBlock is a terminal implementation of a tetris matching game similar to games like Blockudocku

# Running

To run BashBlock from source, you need to have zig (0.13.0) installed and libvaxis cloned into the game's directory. If you do not wish to clone libvaxis into the game's directory, you can also change build.zig.zon so that it accepts a url/hash to libvaxis instead of a path.

See https://ziglang.org/learn/getting-started/ for zig installation instructions, and https://github.com/rockorager/libvaxis for libvaxis

Once BashBlock is cloned, type 'zig build run' in a terminal

# Playing

Controls in BashBlock are simple. Use your arrow keys to move the shapes around, x to switch between shapes, and c to place shapes.

Feel free to change your terminal's font size if you feel like BashBlock is too small. (BashBlock won't crash as long as everything fits)
