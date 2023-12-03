const std = @import("std");
const eql = std.mem.eql;
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;
const expect = std.testing.expect;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const characters = try readFromFile(allocator, "./input.txt");
    defer allocator.free(characters);

    const list = try retrieveNumbers(allocator, characters);
    defer list.deinit();

    const converted = try convertToInt(allocator, list.items);
    defer converted.deinit();

    // combine numbers
    const merged = try mergeNumbers(allocator, converted.items);
    const total = sum(merged.items);

    std.debug.print("total: {any}\n", .{total});
}

test "combine numbers" {
    const numbers = [_]u8{ 1, 2 };

    const merged = try mergeNumbers(test_allocator, numbers[0..]);

    defer merged.deinit();

    const expected = [_]u8{12};
    try expect(eql(u8, merged.items[0..], expected[0..]));
}

fn mergeNumbers(allocator: std.mem.Allocator, nums: []const u8) !ArrayList(u8) {
    var list = ArrayList(u8).init(allocator);

    for (nums, 0..) |num, index| {
        if (index % 2 == 0) {
            if (index + 1 < nums.len) {
                try list.append(num * 10 + nums[index + 1]);
                continue;
            }
        }
    }

    return list;
}

test "convert array from char to int" {
    const items = [_]u8{ '1', '2', '3', '4' };

    const numArray = [_]u8{ 1, 2, 3, 4 };

    const converted = try convertToInt(test_allocator, items[0..]);
    defer converted.deinit();

    try expect(eql(u8, converted.items[0..], numArray[0..]));
}

fn convertToInt(allocator: std.mem.Allocator, items: []const u8) !ArrayList(u8) {
    var list = ArrayList(u8).init(allocator);

    for (items) |item| {
        const formatted = charToDigit(item);
        try list.append(formatted);
    }
    return list;
}

fn charToDigit(c: u8) u8 {
    return c - '0';
}

test "sum an array of integers" {
    const nums = [_]u8{ 1, 2, 3, 4, 5 };
    try expect(sum(nums[0..]) == 15);
}

fn sum(nums: []const u8) u32 {
    var amount: u32 = 0;
    for (nums) |num| {
        amount += num;
    }
    return amount;
}

test "Take lines of text and return first and last number with only numbers" {
    const testData = "12\n34";

    const numbers = try retrieveNumbers(test_allocator, testData);
    defer numbers.deinit();
    const numberArr = [_]u8{ '1', '2', '3', '4' };

    try expect(eql(u8, numbers.items[0..], numberArr[0..]));
}

test "Take lines of text and return first and last number with numbers and letters" {
    const second = "1a2\n3aa4";
    const numberArr = [_]u8{ '1', '2', '3', '4' };

    const secondNumbers = try retrieveNumbers(test_allocator, second);
    defer secondNumbers.deinit();

    try expect(eql(u8, secondNumbers.items[0..], numberArr[0..]));
}

test "Take lines of text and return first and last number with multiple numbers and letters" {
    const second = "58one\n61four29";
    const numberArr = [_]u8{ '5', '8', '6', '9' };

    const secondNumbers = try retrieveNumbers(test_allocator, second);
    defer secondNumbers.deinit();

    try expect(eql(u8, secondNumbers.items[0..], numberArr[0..]));
}

test "Take lines of text and return the only number" {
    const second = "usaiuds1naisdASDJAIOSMDA\nASDIJASdsaidnaidunsa";
    const numberArr = [_]u8{ '1', '1' };

    const secondNumbers = try retrieveNumbers(test_allocator, second);
    defer secondNumbers.deinit();

    try expect(eql(u8, secondNumbers.items[0..], numberArr[0..]));
}

test "Take lines of text with no number and return nothing" {
    const second = "usaiudsnaisdASDJAIOSMDA\nASDIJASdsaidnaidunsa";
    const numberArr = [_]u8{};

    const secondNumbers = try retrieveNumbers(test_allocator, second);
    defer secondNumbers.deinit();

    try expect(eql(u8, secondNumbers.items[0..], numberArr[0..]));
}

test "Single digit no new line character" {
    const second = "nine2sixrtwothree";
    const numberArr = [_]u8{ '2', '2' };

    const secondNumbers = try retrieveNumbers(test_allocator, second);
    defer secondNumbers.deinit();

    try expect(eql(u8, secondNumbers.items[0..], numberArr[0..]));
}

test "Single digit" {
    const second = "2";
    const numberArr = [_]u8{ '2', '2' };

    const secondNumbers = try retrieveNumbers(test_allocator, second);
    defer secondNumbers.deinit();

    try expect(eql(u8, secondNumbers.items[0..], numberArr[0..]));
}

const NumberState = struct {
    has_first: bool = false,
    first_number: ?u8 = null,
    second_number: ?u8 = null,
};

fn retrieveNumbers(allocator: std.mem.Allocator, text: []const u8) !ArrayList(u8) {
    var list = ArrayList(u8).init(allocator);
    var state = NumberState{};

    for (text, 0..) |char, index| {
        try processCharacter(char, index, text.len, &state, &list);
    }
    return list;
}

fn processCharacter(char: u8, index: usize, text_len: usize, state: *NumberState, list: *ArrayList(u8)) !void {
    if (isNumber(char)) {
        if (state.first_number == null) {
            state.first_number = char;
        } else {
            state.second_number = char;
        }
    }

    const is_final_character = index == text_len - 1;

    if (char == '\n' or is_final_character) {
        if (state.second_number != null and state.first_number != null) {
            try list.append(state.first_number.?);
            try list.append(state.second_number.?);
        } else if (state.first_number != null) {
            try list.append(state.first_number.?);
            try list.append(state.first_number.?);
        }
        state.second_number = null;
        state.first_number = null;
        return;
    }
}

test "convert string to number" {
    const str = "1";
    const formatted = try std.fmt.parseInt(u8, str, 10);
    try expect(formatted == 1);
}

// read txt file
test "read from text file" {
    const path = "./test.txt";
    const text = try readFromFile(test_allocator, path);
    defer test_allocator.free(text); // Free the allocated buffer when done

    // these are two separate places in memory. We will need to get the values and compare them?
    try expect(std.mem.eql(u8, text, "123"));
}

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

test "check if character is a number" {
    const two_as_char = '2';
    const num = 2;
    _ = num;
    try expect(isNumber(two_as_char));
}

const ascii = @import("std").ascii;

const TypeInfo = std.meta.TypeInfo;

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

test "is digit" {
    try expect(isNumber('2'));
    try expect(isNumber(2));
}

// sum all from above.
