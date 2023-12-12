const std = @import("std");
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;

const Dict = struct {
    map: std.StringHashMap(std.ArrayList(u8)),
    allocator: std.mem.Allocator = undefined,

    fn init(allocator: std.mem.Allocator) Dict {
        return Dict{
            .map = std.StringHashMap(ArrayList(u8)).init(allocator),
            .allocator = allocator,
        };
    }

    fn deinit(self: *Dict) void {
        var it = self.map.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.deinit();
        }
        self.map.deinit();
    }

    fn add(self: *Dict, key: []const u8, value: u8) !void {
        var res = try self.map.getOrPut(key);
        if (res.found_existing) {
            try res.value_ptr.append(value);
        } else {
            var list = ArrayList(u8).init(self.allocator);
            try list.append(value);
            res.value_ptr.* = list;
        }
    }
};

pub fn main() !void {}

test "wow" {
    var dictionary = Dict.init(test_allocator);
    defer dictionary.deinit();

    try dictionary.add("hi", 1);
    try dictionary.add("hi", 2);
    try dictionary.add("hi", 3);

    try dictionary.add("bye", 2);

    var iterator = dictionary.map.iterator();

    while (iterator.next()) |item| {
        for (item.value_ptr.items) |wow| {
            std.debug.print("\nvalue: {any}\n", .{wow});
        }
    }
}
