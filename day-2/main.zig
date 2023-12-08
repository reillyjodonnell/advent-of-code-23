const std = @import("std");
const reader = @import("reader.zig");
const sum = @import("sum.zig");

const expect = std.testing.expect;
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;

const red_maximum: u8 = 12;
const green_maximum: u8 = 13;
const blue_maximum: u8 = 14;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const text = try reader.readFromFile(allocator, "input.txt");
    var tokenizer = std.mem.tokenize(u8, text, "\n");

    var games = ArrayList(Game).init(allocator);
    defer games.deinit();

    while (tokenizer.next()) |line| {
        var game = try parseGame(allocator, line);
        try games.append(game);
    }

    std.debug.print("\nnumber of games: {any}\n", .{games.items.len});

    var validIds = ArrayList(u8).init(allocator);
    defer validIds.deinit();
    for (games.items) |*game| {
        if (isValidGame(game)) {
            try validIds.append(game.id);
        }
    }

    std.debug.print("\nsum: {d}\n", .{sum.sum(u8, validIds.items[0..])});

    var numbers = ArrayList(u32).init(allocator);
    defer numbers.deinit();

    // find minimum cubes to make games possible
    for (games.items) |*game| {
        var minimum = findMinimum(game);
        var multiply = multiplyMinCube(&minimum);
        // multiply the rgb for each of them

        try numbers.append(multiply);
    }
    std.debug.print("\nsum: {any}\n", .{sum.sum(u32, numbers.items)});

    //sum each multiplied value

}

test "Multiply by number specified in min cubes" {
    var min_cube = MinimumCubes{};
    min_cube.setValue(Color.Red, 1);
    min_cube.setValue(Color.Green, 2);
    min_cube.setValue(Color.Blue, 3);

    try expect(multiplyMinCube(&min_cube) == 6);
}

fn multiplyMinCube(cube: *MinimumCubes) u32 {
    return @as(u32, cube.red) * @as(u32, cube.green) * @as(u32, cube.blue);
}

const MinimumCubes = struct {
    red: u8 = 0,
    green: u8 = 0,
    blue: u8 = 0,

    fn setValue(self: *MinimumCubes, color: Color, count: u8) void {
        switch (color) {
            .Red => self.red = count,
            .Green => self.green = count,
            .Blue => self.blue = count,
        }
    }
};

test "Find minimum cubes to make game possible" {
    var game = Game.init(test_allocator);
    defer game.deinit();

    var round_one = Round{};
    round_one.setValue(Color.Red, 1);
    round_one.setValue(Color.Green, 1);
    round_one.setValue(Color.Blue, 1);

    try game.addRound(round_one);

    var expected_min = MinimumCubes{};
    expected_min.setValue(Color.Red, 1);
    expected_min.setValue(Color.Green, 1);
    expected_min.setValue(Color.Blue, 1);

    var actual = findMinimum(&game);

    try expect(expected_min.red == actual.red);
    try expect(expected_min.green == actual.green);
    try expect(expected_min.blue == actual.blue);
}

fn findMinimum(game: *Game) MinimumCubes {
    var highest_red: u8 = 0;
    var highest_green: u8 = 0;
    var highest_blue: u8 = 0;

    for (game.getRounds().items) |*round| {
        if (round.getRed() > highest_red) {
            highest_red = round.getRed();
        }
        if (round.getGreen() > highest_green) {
            highest_green = round.getGreen();
        }
        if (round.getBlue() > highest_blue) {
            highest_blue = round.getBlue();
        }
    }

    var expected_min = MinimumCubes{};
    expected_min.setValue(Color.Red, highest_red);
    expected_min.setValue(Color.Green, highest_green);
    expected_min.setValue(Color.Blue, highest_blue);

    return expected_min;
}

test "do any rounds surpass the limit" {
    var game = Game.init(test_allocator);
    defer game.deinit();

    var round = Round{};
    round.setValue(Color.Blue, 2);
    round.setValue(Color.Red, 1);
    round.setValue(Color.Green, 2);

    try game.addRound(round);

    try expect(isValidGame(&game));
}

fn isValidGame(game: *Game) bool {
    return !checkIfRoundsInGameExceedMaximum(game.getRounds());
}

test "put into struct" {
    var round = Round{};
    round.setValue(Color.Red, 12);
    try expect(round.getRed() == 12);

    round.setValue(Color.Green, 13);
    try expect(round.getGreen() == 13);

    round.setValue(Color.Blue, 14);
    try expect(round.getBlue() == 14);
}

const Color = enum { Red, Green, Blue };

const Round = struct {
    red: u8 = 0,
    green: u8 = 0,
    blue: u8 = 0,

    fn getValue(self: *Round, color: Color) u8 {
        switch (color) {
            .Red => return self.red,
            .Green => return self.green,
            .Blue => return self.blue,
        }
    }

    fn setValue(self: *Round, color: Color, count: u8) void {
        switch (color) {
            .Red => self.red = count,
            .Green => self.green = count,
            .Blue => self.blue = count,
        }
    }

    fn getRed(self: *Round) u8 {
        return self.red;
    }

    fn getGreen(self: *Round) u8 {
        return self.green;
    }

    fn getBlue(self: *Round) u8 {
        return self.blue;
    }
};

test "Create new game" {
    var game = Game.init(test_allocator);
    defer game.deinit();
    game.setId(0);
    const id = game.getId();

    try expect(id == 0);

    // store results of each round in game
    var round_one = Round{};
    round_one.setValue(Color.Red, 1);
    round_one.setValue(Color.Green, 2);
    round_one.setValue(Color.Blue, 3);

    try game.addRound(round_one);

    var round_two = Round{};
    round_two.setValue(Color.Red, 1);
    round_two.setValue(Color.Green, 3);

    try game.addRound(round_two);

    try expect(game.getRounds().items.len == 2);
}

const Game = struct {
    id: u8 = 0,
    rounds: ArrayList(Round) = undefined,

    fn init(allocator: std.mem.Allocator) Game {
        return Game{
            .id = 0,
            .rounds = ArrayList(Round).init(allocator),
        };
    }

    fn deinit(self: *Game) void {
        self.rounds.deinit();
    }

    fn getId(self: *Game) u8 {
        return self.id;
    }
    fn setId(self: *Game, id: u8) void {
        self.id = id;
    }
    fn addRound(self: *Game, round: Round) !void {
        try self.rounds.append(round);
    }
    fn getRounds(self: *Game) ArrayList(Round) {
        return self.rounds;
    }
};

test "check if value surpasses limit for a round" {
    var round_one = Round{};

    round_one.setValue(Color.Red, red_maximum - 2);
    round_one.setValue(Color.Blue, blue_maximum + 1);

    const exceedsValueForRed = exceedsSpecifiedValueByColor(&round_one, Color.Red, red_maximum);

    try expect(!exceedsValueForRed);

    const exceedsValueForBlue = exceedsSpecifiedValueByColor(&round_one, Color.Blue, blue_maximum);

    try expect(exceedsValueForBlue);
}

fn exceedsSpecifiedValueByColor(round: *Round, color: Color, value: u8) bool {
    return round.getValue(color) > value;
}

test "If game contains value that surpasses maximum" {
    var round_one = Round{};

    round_one.setValue(Color.Red, 4);
    round_one.setValue(Color.Blue, 6);

    var round_two = Round{};

    round_two.setValue(Color.Red, red_maximum + 1);
    round_two.setValue(Color.Blue, 2);

    var game = Game.init(test_allocator);
    defer game.deinit();
    game.setId(0);

    try game.addRound(round_one);
    try game.addRound(round_two);

    const doesSurpassMaximum = checkIfRoundsInGameExceedMaximum(game.rounds);

    try expect(doesSurpassMaximum);
}

fn checkIfRoundsInGameExceedMaximum(rounds: ArrayList(Round)) bool {
    if (rounds.items.len == 0) return false;

    for (rounds.items) |round| {
        if (round.red > red_maximum or round.green > green_maximum or round.blue > blue_maximum) {
            return true;
        }
    }
    return false;
}

test "Create a game with 1 round" {
    const text_example_1 = "Game 1: 255 red, 3 blue, 1 green";

    var game_1 = try parseGame(test_allocator, text_example_1);
    defer game_1.deinit();
    try expect(game_1.id == 1);
    try expect(game_1.rounds.items.len == 1);
}

test "Create a game with 2 or more rounds" {
    const text_example_1 = "Game 2: 255 red, 3 blue, 1 green; 10 blue, 10 red, 1 green";

    var game_1 = try parseGame(test_allocator, text_example_1);
    defer game_1.deinit();
    try expect(game_1.id == 2);
    try expect(game_1.rounds.items.len == 2);
}

fn parseGame(allocator: std.mem.Allocator, stream: []const u8) !Game {
    var tokenizer = std.mem.tokenize(u8, stream, ":");
    var game = Game.init(allocator);
    // game id
    const idToken = tokenizer.next();
    const id = try parseGameId(idToken.?);
    game.setId(id);

    // parse rounds
    if (tokenizer.next()) |next| {
        var round_tokenizer = std.mem.tokenize(u8, next, ";");

        while (round_tokenizer.next()) |round_token| {
            var round = try parseRound(round_token);
            try game.addRound(round);
        }
    }

    return game;
}

fn parseRound(token: []const u8) !Round {
    var round = Round{};

    var comma_separated = std.mem.tokenize(u8, token, ",");
    while (comma_separated.next()) |wow| {
        const trimmedInput = std.mem.trim(u8, wow, " ");
        const spaceIndex = std.mem.indexOf(u8, trimmedInput, " ") orelse return error.InvalidFormat;
        const numberStr = trimmedInput[0..spaceIndex];
        const textStr = trimmedInput[spaceIndex + 1 ..];

        const number = try std.fmt.parseInt(u8, numberStr, 10);

        const color = colorFromString(textStr);

        if (color) |col| {
            round.setValue(col, number);
        }
    }
    return round;
}

fn parseGameId(token: []const u8) !u8 {
    // the last character should be a :
    const id = token[5..];

    return try std.fmt.parseInt(u8, id, 10);
}

fn colorFromString(str: []const u8) ?Color {
    if (std.mem.eql(u8, str, "red")) {
        return Color.Red;
    } else if (std.mem.eql(u8, str, "green")) {
        return Color.Green;
    } else if (std.mem.eql(u8, str, "blue")) {
        return Color.Blue;
    } else {
        return null;
    }
}
