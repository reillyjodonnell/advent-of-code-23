const std = @import("std");
const expect = std.testing.expect;
const eql = std.mem.eql;
const test_allocator = std.testing.allocator;

pub fn main() !void {
    std.debug.print("hello world!", .{});
}

test "state machine for parsing numbers out of string (when just numbers)" {
    const level_easy = "123";
    const actual = try parseNumbersFromString(test_allocator, level_easy);
    defer actual.deinit();
    try expect(eql(u8, actual.items[0..], level_easy));
}

test "state machine for parsing numbers out of string (when just letters)" {
    const level_easy = "one";
    const actual = try parseNumbersFromString(test_allocator, level_easy);
    defer actual.deinit();
    const expected = "1";
    try expect(eql(u8, actual.items[0..], expected));
}

test "state machine for parsing numbers out of string (when letters and numbers)" {
    const level_easy = "one2threefour5";
    const actual = try parseNumbersFromString(test_allocator, level_easy);
    defer actual.deinit();
    const expected = "12345";
    try expect(eql(u8, actual.items[0..], expected));
}

test "state machine for parsing numbers out of string when sharing letters" {
    const level_easy = "lpfoneight";

    const actual = try parseNumbersFromString(test_allocator, level_easy);
    defer actual.deinit();

    const expected = "18";

    try expect(eql(u8, actual.items[0..], expected));
}

fn parseNumbersFromString(allocator: std.mem.Allocator, letters: []const u8) !std.ArrayList(u8) {
    var word_buffer = std.ArrayList(u8).init(allocator);
    defer word_buffer.deinit();

    var parsedNumbers = std.ArrayList(u8).init(allocator);
    errdefer parsedNumbers.deinit(); // Clean up if an error occurs

    for (letters) |letter| {
        try word_buffer.append(letter);

        switch (letter) {
            // append if a number
            '0'...'9' => {
                try parsedNumbers.append(letter);
                word_buffer.clearRetainingCapacity();
            },
            'a'...'z' => {
                if (spellsNumberOneThroughNine(word_buffer.items)) |num| {
                    try parsedNumbers.append(num);
                    word_buffer.clearRetainingCapacity();
                    // this shares the letter i.e.
                    // oneight becomes one and eight bc of the shared e
                    try word_buffer.append(letter);
                }
                if (!isSpellingNumber(word_buffer.items)) {
                    // we need to append all of the letters not just the "last" one
                    var copy_buffer = std.ArrayList(u8).init(allocator);
                    defer copy_buffer.deinit();
                    try copy_buffer.appendSlice(word_buffer.items[1..]);
                    word_buffer.clearRetainingCapacity();
                    try word_buffer.appendSlice(copy_buffer.items[0..]);
                }
            },
            else => {},
        }
    }

    return parsedNumbers;
}

test "isNumber" {
    const number = '1';
    try expect(isNumber(number));

    const not_a_number = "wow";
    try expect(!isNumber(not_a_number));
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

test "Is spelling number" {
    try expect(isSpellingNumber("on"));
    try expect(isSpellingNumber("tw"));
    try expect(!isSpellingNumber("wha"));
    try expect(!isSpellingNumber("nis"));
}

const Numbers = struct { one: []const u8 = "one", two: []const u8 = "two", three: []const u8 = "three", four: []const u8 = "four", five: []const u8 = "five", six: []const u8 = "six", seven: []const u8 = "seven", eight: []const u8 = "eight", nine: []const u8 = "nine" };

fn isSpellingNumber(letters: []const u8) bool {
    const nums = Numbers{};

    if (letters.len <= nums.one.len and eql(u8, nums.one[0..letters.len], letters)) return true;
    if (letters.len <= nums.two.len and eql(u8, nums.two[0..letters.len], letters)) return true;
    if (letters.len <= nums.three.len and eql(u8, nums.three[0..letters.len], letters)) return true;
    if (letters.len <= nums.four.len and eql(u8, nums.four[0..letters.len], letters)) return true;
    if (letters.len <= nums.five.len and eql(u8, nums.five[0..letters.len], letters)) return true;
    if (letters.len <= nums.six.len and eql(u8, nums.six[0..letters.len], letters)) return true;
    if (letters.len <= nums.seven.len and eql(u8, nums.seven[0..letters.len], letters)) return true;
    if (letters.len <= nums.eight.len and eql(u8, nums.eight[0..letters.len], letters)) return true;
    if (letters.len <= nums.nine.len and eql(u8, nums.nine[0..letters.len], letters)) return true;

    return false;
}

fn doStringsMatch(string_one: []const u8, string_two: []const u8) bool {
    return eql(u8, string_one, string_two);
}

fn spellsNumberOneThroughNine(string: []const u8) ?u8 {
    const nums = Numbers{};
    if (doStringsMatch(string, nums.one)) {
        return '1';
    }
    if (doStringsMatch(string, nums.two)) {
        return '2';
    }
    if (doStringsMatch(string, nums.three)) {
        return '3';
    }
    if (doStringsMatch(string, nums.four)) {
        return '4';
    }
    if (doStringsMatch(string, nums.five)) {
        return '5';
    }
    if (doStringsMatch(string, nums.six)) {
        return '6';
    }
    if (doStringsMatch(string, nums.seven)) {
        return '7';
    }
    if (doStringsMatch(string, nums.eight)) {
        return '8';
    }
    if (doStringsMatch(string, nums.nine)) {
        return '9';
    }

    return null;
}
