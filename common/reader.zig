const std = @import("std");

pub fn readFromFile(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});

    // get file size to dynamically allocate mem;
    const file_size = try file.getEndPos();

    const memory = try allocator.alloc(u8, file_size);

    const size = try file.read(memory);
    _ = size;

    // Close the file
    file.close();

    return memory;
}
