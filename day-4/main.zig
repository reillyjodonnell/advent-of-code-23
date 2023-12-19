const std = @import("std");
const reader = @import("./reader.zig");
const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
const eql = std.mem.eql;
const expectError = std.testing.expectError;
const expectEqualDeep = std.testing.expectEqualDeep;
const ArrayList = std.ArrayList;
pub fn main() !void {}

test "testing" {
    var allocator = test_allocator;
    const text = try reader.readFromFile(allocator, "input.txt");
    defer allocator.free(text);
    var tokenizer = std.mem.tokenize(u8, text, "\n");

    var list_of_cards = ArrayList(Card).init(allocator);
    defer list_of_cards.deinit();

    while (tokenizer.next()) |line| {
        var card = try parseLineIntoCard(line);
        try list_of_cards.append(card);
    }
    var sum: u64 = 0;
    for (list_of_cards.items) |*individual_card| {
        sum += individual_card.getPoints();
    }
    std.debug.print("\nsum:{d}\n", .{sum});
}

test "should read the first letter in the input" {
    var text = try reader.readFromFile(test_allocator, "./input.txt");
    defer test_allocator.free(text);
    try expect(text[0] == 'C');

    // read line and make each a struct of card
}

test "Create card struct " {
    // card should have an array of winning numbers and an array of picked numbers
    var card_one = Card{ .id = 0 };
    var card_one_expected_winning_numbers = [10]u8{ 95, 57, 30, 62, 11, 5, 9, 3, 72, 87 };
    var card_one_numbers = [25]u8{ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25 };

    card_one.setWinningNumbers(card_one_expected_winning_numbers);
    try expectEqualDeep(card_one_expected_winning_numbers, try card_one.getWinningNumbers());
    card_one.setCardNumbers(card_one_numbers);
    try expectEqualDeep(card_one_numbers, try card_one.getCardNumbers());

    var card_two = Card{ .id = 0 };
    try expectError(CardError.WinningNumbersNotSet, card_two.getWinningNumbers());
    try expectError(CardError.CardNumbersNotSet, card_two.getCardNumbers());
}

const CardError = error{ WinningNumbersNotSet, CardNumbersNotSet };

const Card = struct {
    id: u8,
    winning_numbers: [10]u8 = [10]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    card_numbers: [25]u8 = [25]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },

    fn getId(self: *Card) u8 {
        return self.id;
    }
    fn setId(self: *Card, id: u8) void {
        self.id = id;
    }
    fn getWinningNumbers(self: *Card) ![10]u8 {
        if (self.winning_numbers[0] == 0) {
            return CardError.WinningNumbersNotSet;
        }
        return self.winning_numbers;
    }
    fn setWinningNumbers(self: *Card, numbers: [10]u8) void {
        self.winning_numbers = numbers;
    }

    fn getCardNumbers(self: *Card) ![25]u8 {
        if (self.card_numbers[0] == 0) {
            return CardError.CardNumbersNotSet;
        }
        return self.card_numbers;
    }

    fn setCardNumbers(self: *Card, numbers: [25]u8) void {
        self.card_numbers = numbers;
    }

    fn getPoints(self: *Card) u32 {
        var matches = getNumberOfMatches(self.winning_numbers, self.card_numbers);
        return getNumberOfPoints(matches);
    }
};

test "Return number of points based on matches" {
    try expect(getNumberOfPoints(10) == 512);
    try expect(getNumberOfPoints(1) == 1);
    try expect(getNumberOfPoints(2) == 2);
    try expect(getNumberOfPoints(0) == 0);
}

fn getNumberOfPoints(matches: u8) u32 {
    if (matches == 0) {
        return 0; // or return 1, depending on your requirements
    }
    var result: u32 = 1;
    var i: usize = 0;
    while (i < matches - 1) : (i += 1) {
        result *= 2;
    }
    return result;
}
// 1 2 4 8 16 32 64 128 256 512

test "see how many matches an array has against another array" {
    var card_numbers: [25]u8 = [25]u8{ 94, 72, 74, 98, 23, 57, 62, 14, 30, 3, 73, 49, 80, 96, 20, 60, 17, 35, 11, 63, 87, 9, 6, 5, 95 };
    var winning_numbers: [10]u8 = [10]u8{ 95, 57, 30, 62, 11, 5, 9, 3, 72, 87 };
    try expect(getNumberOfMatches(winning_numbers, card_numbers) == 10);
}

fn getNumberOfMatches(arr1: [10]u8, arr2: [25]u8) u8 {
    var matches: u8 = 0;

    for (arr1) |arr1_value| {
        for (arr2) |arr2_value| {
            if (arr2_value == arr1_value) {
                matches += 1;
                continue;
            }
        }
    }
    return matches;
}

test "points for card" {
    var card = Card{ .id = 0 };
    var card_numbers: [25]u8 = [25]u8{ 94, 72, 74, 98, 23, 57, 62, 14, 30, 3, 73, 49, 80, 96, 20, 60, 17, 35, 11, 63, 87, 9, 6, 5, 95 };
    var winning_numbers: [10]u8 = [10]u8{ 95, 57, 30, 62, 11, 5, 9, 3, 72, 87 };

    card.setCardNumbers(card_numbers);
    card.setWinningNumbers(winning_numbers);
    try expect(card.getPoints() == 512);
}

test "read from line to create a struct" {
    var text: []const u8 = "Card   1: 95 57 30 62 11  5  9  3 72 87 | 94 72 74 98 23 57 62 14 30  3 73 49 80 96 20 60 17 35 11 63 87  9  6  5 95";
    var card_one: Card = try parseLineIntoCard(text);
    var expected_numbers: [25]u8 = [25]u8{ 94, 72, 74, 98, 23, 57, 62, 14, 30, 3, 73, 49, 80, 96, 20, 60, 17, 35, 11, 63, 87, 9, 6, 5, 95 };
    _ = expected_numbers;
    try expect(card_one.getId() == 1);
    var expected_winning_numbers: [10]u8 = [10]u8{ 95, 57, 30, 62, 11, 5, 9, 3, 72, 87 };
    try expectEqualDeep(card_one.getWinningNumbers(), expected_winning_numbers);

    var expected_card_numbers: [25]u8 = [25]u8{ 94, 72, 74, 98, 23, 57, 62, 14, 30, 3, 73, 49, 80, 96, 20, 60, 17, 35, 11, 63, 87, 9, 6, 5, 95 };
    card_one.setCardNumbers(try parseCardNumbers(text));
    try expectEqualDeep(card_one.getCardNumbers(), expected_card_numbers);
}

fn parseLineIntoCard(text: []const u8) !Card {
    // var id: u8 = parseCardId(text);

    var card_id = try parseCardId(text);
    var winning_numbers = try parseWinningNumbers(text);
    var numbers = try parseCardNumbers(text);

    var card = Card{ .id = card_id };
    card.setWinningNumbers(winning_numbers);
    card.setCardNumbers(numbers);
    return card;
}

test "parse card numbers" {
    var text: []const u8 = "Card   1: 95 57 30 62 11  5  9  3 72 87 | 94 72 74 98 23 57 62 14 30  3 73 49 80 96 20 60 17 35 11 63 87  9  6  5 95";
    var parsed = try parseCardNumbers(text);
    var expected: [25]u8 = [25]u8{ 94, 72, 74, 98, 23, 57, 62, 14, 30, 3, 73, 49, 80, 96, 20, 60, 17, 35, 11, 63, 87, 9, 6, 5, 95 };
    try expectEqualDeep(expected, parsed);
}

fn parseCardNumbers(text: []const u8) ![25]u8 {
    var buffer: [25]u8 = [25]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    var iter = std.mem.split(u8, text, ":");

    var trash = iter.next();
    _ = trash;

    var combined_numbers = iter.next();

    var numbers = std.mem.split(u8, combined_numbers.?, "|");
    var winning_numbers = numbers.next();
    _ = winning_numbers;
    if (numbers.next()) |next| {
        var tokens = std.mem.tokenizeAny(u8, next, " ");
        var index: usize = 0;
        while (tokens.next()) |token| {
            var to_u8 = try std.fmt.parseInt(u8, token, 10);
            buffer[index] = to_u8;
            index += 1;
        }
    }

    return buffer;
}

test "parse winning numbers" {
    var text: []const u8 = "Card   1: 95 57 30 62 11  5  9  3 72 87 | 94 72 74 98 23 57 62 14 30  3 73 49 80 96 20 60 17 35 11 63 87  9  6  5 95";
    var parsed = try parseWinningNumbers(text);
    var expected: [10]u8 = [10]u8{ 95, 57, 30, 62, 11, 5, 9, 3, 72, 87 };
    try expectEqualDeep(expected, parsed);
}

fn parseWinningNumbers(text: []const u8) ![10]u8 {
    var buffer: [10]u8 = [10]u8{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
    var iter = std.mem.split(u8, text, ":");

    var trash = iter.next();
    _ = trash;

    var numbers = iter.next();

    var winning_numbers = std.mem.split(u8, numbers.?, "|");
    if (winning_numbers.next()) |next| {
        var tokens = std.mem.tokenizeAny(u8, next, " ");
        var index: usize = 0;
        while (tokens.next()) |token| {
            var to_u8 = try std.fmt.parseInt(u8, token, 10);
            buffer[index] = to_u8;
            index += 1;
        }
    }

    return buffer;
}

test "parse card id" {
    var text: []const u8 = "Card   1: 95 57 30 62 11  5  9  3 72 87 | 94 72 74 98 23 57 62 14 30  3 73 49 80 96 20 60 17 35 11 63 87  9  6  5 95";

    try expect(try parseCardId(text) == 1);
}

fn parseCardId(text: []const u8) !u8 {
    var number: u8 = 0;
    var iter = std.mem.split(u8, text, ":");
    var card_id_section = iter.next();
    if (card_id_section) |card_id| {
        const first_number = card_id[5];
        if (std.ascii.isAlphanumeric(first_number)) {
            var unparsed = card_id[6..];
            number = try std.fmt.parseInt(u8, unparsed, 10);
        } else {
            var unparsed = card_id[7] - '0';
            number = @as(u8, unparsed);
        }
        return number;
    }

    return number;
}
