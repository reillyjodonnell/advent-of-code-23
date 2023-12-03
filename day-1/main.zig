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
    const data = "12\n34";
    const expected = [_]u8{ '1', '2', '3', '4' };

    try expectDataToMatchExpectedForRetrievedNumbers(data, expected[0..]);
}

test "Take lines of text and return first and last number with numbers and letters" {
    const data = "1a2\n3aa4";
    const expected = [_]u8{ '1', '2', '3', '4' };

    try expectDataToMatchExpectedForRetrievedNumbers(data, expected[0..]);
}

test "Take lines of text and return first and last number with multiple numbers and letters" {
    const data = "58adsad\n61asd29";
    const expected = [_]u8{ '5', '8', '6', '9' };
    try expectDataToMatchExpectedForRetrievedNumbers(data, expected[0..]);
}

test "Take lines of text and return the only number" {
    const data = "usaiuds1naisdASDJAIOSMDA\nASDIJASdsaidnaidunsa";
    const expected = [_]u8{ '1', '1' };

    try expectDataToMatchExpectedForRetrievedNumbers(data, expected[0..]);
}

test "Take lines of text with no number and return nothing" {
    const data = "usaiudsnaisdASDJAIOSMDA\nASDIJASdsaidnaidunsa";
    const expected = [_]u8{};
    try expectDataToMatchExpectedForRetrievedNumbers(data, expected[0..]);
}

test "Single digit no new line character" {
    const data = "sdfs2ssdee";
    const expected = [_]u8{ '2', '2' };
    try expectDataToMatchExpectedForRetrievedNumbers(data, expected[0..]);
}

// test "Alpha numeric and number" {
//     const data = "58one";
//     const expected = [_]u8{ '5', '1' };
//     try expectDataToMatchExpectedForRetrievedNumbers(data, expected[0..]);
// }

fn expectDataToMatchExpectedForRetrievedNumbers(data: []const u8, expected: []const u8) !void {
    const num = try retrieveNumbers(test_allocator, data);
    defer num.deinit();

    try expect(eql(u8, num.items[0..], expected));
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

    // var isSpellingNumber = isPartialNumberSpelled(&char[0..]);

    // max length is 5 for an array
    // var buffer = null;

    // while (isSpellingNumber) {
    //     // read the next letter

    //     // check if it's still spelling
    //     isSpellingNumber = isPartialNumberSpelled(buffer);
    // }

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

test "is digit" {
    try expect(isNumber('2'));
    try expect(isNumber(2));
}

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

const Numbers = struct { one: []const u8 = "one", two: []const u8 = "two", three: []const u8 = "three", four: []const u8 = "four", five: []const u8 = "five", six: []const u8 = "six", seven: []const u8 = "seven", eight: []const u8 = "eight", nine: []const u8 = "nine" };

test "detect what number string is" {
    const nums = Numbers{};
    const one = nums.one;
    const two = nums.two;

    const fail: []const u8 = "wut";

    // Tests for valid number strings
    try expect(std.mem.eql(u8, try whatNumberIsThis(one), one));
    try expect(std.mem.eql(u8, try whatNumberIsThis(two), two));

    // Test for invalid string
    try std.testing.expectError(NumberError.NotANumber, whatNumberIsThis(fail));
}

const NumberError = error{NotANumber};
fn whatNumberIsThis(string: []const u8) ![]const u8 {
    const nums = Numbers{};
    if (doStringsMatch(string, nums.one)) {
        return nums.one;
    }
    if (doStringsMatch(string, nums.two)) {
        return nums.two;
    }
    if (doStringsMatch(string, nums.three)) {
        return nums.three;
    }
    if (doStringsMatch(string, nums.four)) {
        return nums.four;
    }
    if (doStringsMatch(string, nums.five)) {
        return nums.five;
    }
    if (doStringsMatch(string, nums.six)) {
        return nums.six;
    }
    if (doStringsMatch(string, nums.seven)) {
        return nums.seven;
    }
    if (doStringsMatch(string, nums.eight)) {
        return nums.eight;
    }
    if (doStringsMatch(string, nums.nine)) {
        return nums.nine;
    }

    return NumberError.NotANumber;
}

test "do strings match" {
    const nums = Numbers{};
    try expect(doStringsMatch(nums.one, nums.one));
}

fn doStringsMatch(string_one: []const u8, string_two: []const u8) bool {
    return eql(u8, string_one, string_two);
}

test "check if string is spelling out a number" {
    const one = "on";

    try expect(isPartialNumberSpelled(one));

    const invalidRandom = "as";

    try expect(!isPartialNumberSpelled(invalidRandom));

    const invalidOne = "onee";

    try expect(!isPartialNumberSpelled(invalidOne));

    const seven = "sev";

    try expect(isPartialNumberSpelled(seven));

    const invalidSeven = "sevv";

    try expect(!isPartialNumberSpelled(invalidSeven));
}

fn isLengthLarger(a: []const u8, b: []const u8) bool {
    return a.len > b.len;
}

fn isPartialNumberSpelled(letters: []const u8) bool {
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
