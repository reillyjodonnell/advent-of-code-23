const std = @import("std");

pub fn main() !void {
    std.debug.print("Hello world!", .{});
}

const expect = std.testing.expect;
// read txt file
test "read from text file" {
    const path = "./test.txt";
    const text = try readFromFile("./text.txt");
    // these are two separate places in memory. We will need to get the values and compare them?
    expect(text == "123");
}

pub fn readFromFile(path: []const u8) !u8 {
    _ = path;

    // allocate buffer.

    // read from path

    // put content in buffer

    // return buffer

}

// read line by line

// store first and last int of each line (for all lines)

// sum all from above.
