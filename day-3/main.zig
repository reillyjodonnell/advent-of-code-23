const std = @import("std");
const expect = std.testing.expect;
const ArrayList = std.ArrayList;
const reader = @import("reader.zig");
const test_allocator = std.testing.allocator;
const sum = @import("sum.zig");

pub fn main() !void {}

fn isNumber(input: anytype) bool {
    const inputType = @TypeOf(input);

    // Check if the input is a u8 (character type) and a digit
    if (inputType == u8) {
        return input >= '0' and input <= '9';
    }

    // Use @typeInfo to check for integer types
    switch (@typeInfo(inputType)) {
        .Int => return true, // It's an integer type
        .ComptimeInt => return true,
        else => return false, // Not an integer type
    }
}

test "detects symbol in 8 directions around text" {
    const text = try reader.readFromFile(test_allocator, "input.txt");
    defer test_allocator.free(text);
    var items = try numbersAroundTokens(test_allocator, text);
    defer items.deinit();
    var iterator = items.map.iterator();

    var total_sum: u32 = 0;

    while (iterator.next()) |item| {
        const numbersList = item.value_ptr; // The ArrayList of numbers

        var local_sum: u32 = 1;

        if (numbersList.items.len == 1) continue;
        // Iterate over the list of numbers and print each one
        for (numbersList.items) |num| {
            local_sum = local_sum * num;
        }
        total_sum = total_sum + if (local_sum > 0) local_sum else 0;

        local_sum = 1;
    }
    try expect(total_sum == 73074886);
}

const NumberDict = struct {
    map: std.StringHashMap(ArrayList(u10)),
    allocator: std.mem.Allocator = undefined,

    fn init(allocator: std.mem.Allocator) NumberDict {
        return NumberDict{
            .map = std.StringHashMap(ArrayList(u10)).init(allocator),
            .allocator = allocator,
        };
    }

    fn deinit(self: *NumberDict) void {
        var it = self.map.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.deinit(); // Deinitialize the value (ArrayList)
            self.allocator.free(entry.key_ptr.*); // Free the memory for the key copy
        }
        self.map.deinit(); // Deinitialize the map itself
    }

    fn addEntry(self: *NumberDict, key: [2]u8, value: u10) !void {
        var buffer: [2]u8 = undefined;
        buffer[0] = key[0];
        buffer[1] = key[1];
        // if we don't do this we lose the reference
        var key_copy = try self.allocator.dupe(u8, buffer[0..]);
        var res = try self.map.getOrPut(key_copy);
        if (res.found_existing) {
            self.allocator.free(key_copy);
            try res.value_ptr.append(value);
        } else {
            var list = ArrayList(u10).init(self.allocator);
            try list.append(value);
            res.value_ptr.* = list;
        }
    }

    fn getEntry(self: *NumberDict, key: []const u8) ?std.ArrayList(u10) {
        return self.map.get(key);
    }

    fn getAllEntries(self: *NumberDict) std.AutoHashMap([]const u8, std.ArrayList(u10)).Iterator {
        return self.map.iterator();
    }
};

fn usizeToU8(value: usize) ?u8 {
    if (value <= 255) {
        const return_type: u8 = @intCast(value);
        return return_type;
    } else {
        return null; // Return null or handle the error if the value is out of range
    }
}

const Coordinate = struct {
    x: u8,
    y: u8,
};

fn createCoordKey(allocator: std.mem.Allocator, coord: Coordinate) ![]u8 {
    return std.fmt.allocPrint(allocator, "{},{}", .{ coord.x, coord.y });
}

test "return coordinates of symbol around character" {
    // the 7th character
    var col: usize = 6;
    var row: usize = 0;

    const text = try reader.readFromFile(test_allocator, "input.txt");
    defer test_allocator.free(text);

    const arr = createArrayOfCoordinates(text);

    const symbol_coords = getCoordinatesForNearestSymbol(row, col, arr);

    var expected = [2]u8{ 5, 1 };

    if (symbol_coords[0]) |x| {
        try expect(x == expected[1]);
    }

    if (symbol_coords[1]) |y| {
        try expect(y == expected[0]);
    }
}

fn getCoordinatesForNearestSymbol(row_index: usize, col_index: usize, arr: [150][150]u8) [2]?u8 {
    var symbol_coordinates = [2]?u8{ null, null };

    // arr[y][x] where the first arr is the row, or y axis, second is the col, or x axis.

    if (row_index > 0 and col_index > 0) {
        const top_left = arr[row_index - 1][col_index - 1];
        if (isSymbol(top_left)) {
            symbol_coordinates[0] = usizeToU8(row_index - 1).?;
            symbol_coordinates[1] = usizeToU8(col_index - 1).?;
        }
    }
    if (row_index > 0) {
        const top_middle = arr[row_index - 1][col_index];
        if (isSymbol(top_middle)) {
            symbol_coordinates[0] = usizeToU8(row_index - 1).?;
            symbol_coordinates[1] = usizeToU8(col_index).?;
        }
    }
    if (col_index < 139 and row_index > 0) {
        const top_right = arr[row_index - 1][col_index + 1];
        if (isSymbol(top_right)) {
            symbol_coordinates[0] = usizeToU8(row_index - 1).?;
            symbol_coordinates[1] = usizeToU8(col_index + 1).?;
        }
    }
    if (col_index > 0) {
        const middle_left = arr[row_index][col_index - 1];
        if (isSymbol(middle_left)) {
            symbol_coordinates[0] = usizeToU8(row_index).?;
            symbol_coordinates[1] = usizeToU8(col_index - 1).?;
        }
    }
    if (col_index < 139) {
        const middle_right = arr[row_index][col_index + 1];
        if (isSymbol(middle_right)) {
            symbol_coordinates[0] = usizeToU8(row_index).?;
            symbol_coordinates[1] = usizeToU8(col_index + 1).?;
        }
    }
    if (row_index < 139 and col_index > 0) {
        const bottom_left = arr[row_index + 1][col_index - 1];
        if (isSymbol(bottom_left)) {
            symbol_coordinates[0] = usizeToU8(row_index + 1).?;
            symbol_coordinates[1] = usizeToU8(col_index - 1).?;
        }
    }
    if (row_index < 139) {
        const bottom_middle = arr[row_index + 1][col_index];
        if (isSymbol(bottom_middle)) {
            symbol_coordinates[0] = usizeToU8(row_index + 1).?;
            symbol_coordinates[1] = usizeToU8(col_index).?;
        }
    }

    if (row_index < 139 and col_index < 139) {
        const bottom_right = arr[row_index + 1][col_index + 1];
        if (isSymbol(bottom_right)) {
            symbol_coordinates[0] = usizeToU8(row_index + 1).?;
            symbol_coordinates[1] = usizeToU8(col_index + 1).?;
        }
    }
    return symbol_coordinates;
}

test "creating a struct to hold state for looping" {
    var numStruct = NumStruct{};

    try expect(numStruct.number == 0);

    // push some numbers as i'm reading them.
    numStruct.appendNumber('2');

    try expect(numStruct.number == 2);

    numStruct.appendNumber('2');

    try expect(numStruct.number == 22);

    numStruct.reset();

    try expect(numStruct.number == 0);

    try expect(numStruct.coordinates[0] == null);
    try expect(numStruct.coordinates[1] == null);

    var buff: [2]?u8 = [2]?u8{ 0, 2 };
    numStruct.setCoordinates(buff);
    try expect(numStruct.coordinates[0] == buff[0]);
    try expect(numStruct.coordinates[1] == buff[1]);

    numStruct.reset();
    try expect(numStruct.coordinates[0] == null);
    try expect(numStruct.coordinates[1] == null);
}

const NumStruct = struct {
    number: u10 = 0,
    coordinates: [2]?u8 = [2]?u8{ null, null },

    fn appendNumber(self: *NumStruct, num: u8) void {
        self.number = self.number * 10 + @as(u10, @intCast(num - '0'));
        return;
    }

    fn getNumber(self: *NumStruct) u10 {
        return self.number;
    }

    fn getValidCoordinates(self: *NumStruct) ?[2]u8 {
        if (self.coordinates[0]) |x| {
            if (self.coordinates[1]) |y| {
                return [2]u8{ x, y };
            }
        }
        return null;
    }

    fn setCoordinates(self: *NumStruct, coordinates: [2]?u8) void {
        self.coordinates = coordinates;
        return;
    }

    fn reset(self: *NumStruct) void {
        self.number = 0;
        self.coordinates = [2]?u8{ null, null };
        return;
    }
};

fn numbersAroundTokens(allocator: std.mem.Allocator, passed: []const u8) !NumberDict {
    var dictionary = NumberDict.init(allocator);

    const arr = createArrayOfCoordinates(passed);
    var numStruct = NumStruct{};

    for (arr, 0..) |row, row_index| {
        for (row, 0..) |column, col_index| {
            if (isNumber(column)) {
                // append
                numStruct.appendNumber(column);
                // get coords
                if (numStruct.coordinates[0] == null) {
                    numStruct.setCoordinates(getCoordinatesForNearestSymbol(row_index, col_index, arr));
                }
            } else {
                // add to dictionary
                if (numStruct.getValidCoordinates()) |coords| {
                    try dictionary.addEntry(coords, numStruct.getNumber());
                }
                // reset
                numStruct.reset();
            }
        }
    }
    return dictionary;
}

test "tell us if something is a symbol" {
    try expect(!isSymbol('.'));
    try expect(isSymbol('+'));
    try expect(isSymbol('&'));
    try expect(isSymbol('#'));
    try expect(isSymbol('='));
    try expect(isSymbol('/'));
    try expect(isSymbol('*'));
    try expect(isSymbol('$'));
    try expect(!isSymbol('4'));
    try expect(!isSymbol('e'));
}

fn isSymbol(char: u8) bool {
    return !std.ascii.isAlphanumeric(char) and !std.ascii.isAlphabetic(char) and char != '\n' and char != '.';
}

fn createArrayOfCoordinates(text: []const u8) [150][150]u8 {
    var coord: [150][150]u8 = undefined;

    var line: u16 = 0;
    var row: u16 = 0;
    // read each character until we hit a new line character
    for (text) |character| {
        coord[line][row] = character;
        if (character == '\n') {
            row = 0;
            line += 1;
            continue;
        }
        row += 1;
    }
    return coord;
}
