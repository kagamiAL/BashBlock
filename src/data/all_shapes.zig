const l_shape = [_]i8{ 0, 0, 1, 0, -1, 0, 1, 1 };
const inverse_l = [_]i8{ 0, 0, 1, 0, -1, 0, 1, -1 };
const square = [_]i8{ 0, 0, 0, 1, 1, 0, 1, 1 };
const z_shape = [_]i8{ 0, 0, 0, 1, -1, 0, -1, -1 };
const inverse_z = [_]i8{ 0, 0, 0, -1, 1, 0, 1, 1 };
const straight_4 = [_]i8{ 0, 0, -1, 0, 1, 0, 2, 0 };
const straight_5 = [_]i8{ 0, 0, -1, 0, -2, 0, 1, 0, 2, 0 };
const t_shape = [_]i8{ 0, 0, 0, 1, 0, -1, 1, 0 };
const cross = [_]i8{ 0, 0, 1, 0, -1, 0, 0, 1, 0, -1 };
const u_shape = [_]i8{ 0, 0, 0, 1, 0, -1, -1, 1, -1, -1 };
const two = [_]i8{ 0, 0, 0, 1 };
const diag = [_]i8{ 0, 0, -1, 1 };

pub const all_shapes = [_][]const i8{
    &l_shape,
    &square,
    &z_shape,
    &inverse_z,
    &inverse_l,
    &straight_4,
    &straight_5,
    &t_shape,
    &cross,
    &u_shape,
    &two,
    &diag,
};
