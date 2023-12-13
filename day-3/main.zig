const std = @import("std");
const expect = std.testing.expect;
const ArrayList = std.ArrayList;
const reader = @import("reader.zig");
const test_allocator = std.testing.allocator;
const sum = @import("sum.zig");
// read line until you hit a number
// look right and add to list until no more number.

// for each of the numbers check 8 directions around it for a symbol.
// if not discard the number
// push the number to a list
// repeat for every line

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const text = try reader.readFromFile(allocator, "input.txt");
    defer allocator.free(text);
    var nums = try numbersAroundTokens(allocator, text);
    defer nums.deinit();

    var iterator = nums.map.iterator();
    for (iterator.next()) |val| {
        _ = val;
    }
    std.debug.print("numbers: {any}", .{nums.map.iter});

    const summed = sum.sum(u10, nums.items);

    std.debug.print("sum: {d}", .{summed});
}

// turn 2d canvas to 1d array
// group numbers
//    -- how?
//    receive position in array and move to the left until no more, move right until no more. Merge the u8s
// check 8 directions and check if there's a symbol.
// if so keep track and push to array
// sum items in array

// test "find numbers in array" {
//     const example = "......644.....23..432";
//     const expected = [_]u10{ 644, 23, 432 };

//     const actual = try findNumbers(test_allocator, example);
//     defer actual.deinit();

//     for (actual.items, 0..) |number, index| {
//         try expect(number == expected[index]);
//     }
// }

fn findNumbers(allocator: std.mem.Allocator, num: []const u8) !ArrayList(u10) {
    var joined = ArrayList(u10).init(allocator);

    var number: u10 = 0;

    for (num) |value| {
        if (isNumber(value)) {
            number = number * 10 + value - '0';
            continue;
        }
        if (number > 0 and !isNumber(value)) {
            try joined.append(number);
            number = 0;
        }
        continue;
    }
    return joined;
}

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

    var have_matching = ArrayList(u32).init(test_allocator);
    _ = have_matching;

    var total_sum: u32 = 0;

    while (iterator.next()) |item| {
        const key = item.key_ptr;
        _ = key; // The key
        const numbersList = item.value_ptr; // The ArrayList of numbers

        // Print the key
        std.debug.print("\nvalue len: {d}\n", .{numbersList.items.len});

        var local_sum: u32 = 1;

        if (numbersList.items.len == 1) continue;
        // Iterate over the list of numbers and print each one
        for (numbersList.items) |num| {
            local_sum = local_sum * num;
        }
        total_sum = total_sum + if (local_sum > 0) local_sum else 0;

        local_sum = 1;
    }

    std.debug.print("\ntotal: {d}\n", .{total_sum});
    //73075331
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

    fn addEntry(self: *NumberDict, key: []const u8, value: u10) !void {
        // Allocate memory for the key copy
        var keyCopy = try self.allocator.dupe(u8, key);
        var res = try self.map.getOrPut(keyCopy);
        if (res.found_existing) {
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

fn numbersAroundTokens(allocator: std.mem.Allocator, passed: []const u8) !NumberDict {
    var dictionary = NumberDict.init(allocator);
    const arr = createArrayOfCoordinates(passed);
    var has_symbol = false;
    var number: u10 = 0;
    var symbol_coordinates = [2]?u8{ null, null };

    // create a dictionary where the coordinates of the shared symbol are the key and the numbers are the value

    for (arr, 0..) |row, row_index| {
        for (row, 0..) |cell, column_index| {
            if (isNumber(cell)) {
                number = number * 10 + @as(u10, @intCast(cell - '0'));
                // get the 8 things around it
                if (row_index > 0 and column_index > 0) {
                    const top_left = arr[row_index - 1][column_index - 1];
                    if (isSymbol(top_left)) {
                        symbol_coordinates[0] = usizeToU8(row_index - 1).?;
                        symbol_coordinates[1] = usizeToU8(column_index - 1).?;
                        has_symbol = true;
                    }
                }
                if (row_index > 0) {
                    const top_middle = arr[row_index - 1][column_index];
                    if (isSymbol(top_middle)) {
                        symbol_coordinates[0] = usizeToU8(row_index - 1).?;
                        symbol_coordinates[1] = usizeToU8(column_index).?;
                        has_symbol = true;
                    }
                }
                if (row_index > 0 and column_index < 139) {
                    const top_right = arr[row_index - 1][column_index + 1];
                    if (isSymbol(top_right)) {
                        symbol_coordinates[0] = usizeToU8(row_index - 1).?;
                        symbol_coordinates[1] = usizeToU8(column_index + 1).?;
                        has_symbol = true;
                    }
                }
                if (column_index > 0) {
                    const middle_left = arr[row_index][column_index - 1];
                    if (isSymbol(middle_left)) {
                        symbol_coordinates[0] = usizeToU8(row_index).?;
                        symbol_coordinates[1] = usizeToU8(column_index - 1).?;
                        has_symbol = true;
                    }
                }
                if (column_index < 139) {
                    const middle_right = arr[row_index][column_index + 1];
                    if (isSymbol(middle_right)) {
                        symbol_coordinates[0] = usizeToU8(row_index).?;
                        symbol_coordinates[1] = usizeToU8(column_index + 1).?;
                        has_symbol = true;
                    }
                }
                if (row_index < 139 and column_index > 0) {
                    const bottom_left = arr[row_index + 1][column_index - 1];
                    if (isSymbol(bottom_left)) {
                        symbol_coordinates[0] = usizeToU8(row_index + 1).?;
                        symbol_coordinates[1] = usizeToU8(column_index - 1).?;
                        has_symbol = true;
                    }
                }
                if (row_index < 139) {
                    const bottom_middle = arr[row_index + 1][column_index];
                    if (isSymbol(bottom_middle)) {
                        symbol_coordinates[0] = usizeToU8(row_index + 1).?;
                        symbol_coordinates[1] = usizeToU8(column_index).?;
                        has_symbol = true;
                    }
                }
                if (row_index < 139 and column_index < 139) {
                    const bottom_right = arr[row_index + 1][column_index + 1];

                    if (isSymbol(bottom_right)) {
                        symbol_coordinates[0] = usizeToU8(row_index + 1).?;
                        symbol_coordinates[1] = usizeToU8(column_index + 1).?;
                        has_symbol = true;
                    }
                }
            }

            if (number > 0 and !isNumber(cell) and has_symbol) {
                if (symbol_coordinates[0] != null and symbol_coordinates[1] != null) {
                    var buffer: [2]u8 = undefined;
                    buffer[0] = symbol_coordinates[0].?;
                    buffer[1] = symbol_coordinates[1].?;

                    // Create a slice from the buffer
                    const slice: []const u8 = buffer[0..];
                    try dictionary.addEntry(slice, number);
                    number = 0;
                    has_symbol = false;
                    symbol_coordinates[0] = null;
                    symbol_coordinates[1] = null;
                }
            }
            if (number > 0 and !isNumber(cell) and !has_symbol) {
                number = 0;
                symbol_coordinates[0] = null;
                symbol_coordinates[1] = null;
            }
        }
    }
    return dictionary;
}

fn isSymbol(char: u8) bool {
    const period: u8 = '.';
    return !isNumber(char) and char != period and char != '\n';
}

// const Grid = struct {
//     data: ArrayList(u8),

//     fn addCoordinate(self: *Grid, x: u8, y: u8, char: u8) void {
//         _ = char;
//         try self.data.append(generateCoordinate(x, y));
//     }

//     fn generateCoordinate(x: u8, y: u8) u8 {
//         return y * 10 + x;
//     }

//     fn retrieveByCoordinate(x: u8, y: u8) u8 {
//         _ = x;
//         _ = y;

//         // return the character at that position in data;
//         return '.';
//     }
// };

// // const Cell = struct {
// //     x: u16,
// //     y: u16,
// //     character: u8,

// //     fn addCoordinate(self: *Cell, x: u16, y: u16, char: u8) !void {
// //         self.x = x;
// //         self.y = y;
// //         self.character = char;
// //     }
// // };

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

// fn getCoordinates(x: u16, y: u16) u16 {
//     return x * 10 + y;
// }
