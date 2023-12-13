const std = @import("std");

pub fn main() void {
    var name = [4]u8{ 'G', 'o', 'k', 'u' };
    var user = User{
        .id = 1,
        .power = 100,
        // slice it, [4]u8 -> []u8
        .name = name[0..],
    };
    levelUp(user);
    std.debug.print("{s}\n", .{user.name});
}

fn levelUp(user: User) void {
    user.name[2] = '!';
}

pub const User = struct {
    id: u64,
    power: i32,
    // []const u8 -> []u8
    name: []u8,
};
