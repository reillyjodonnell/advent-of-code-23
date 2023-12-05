const std = @import("std");
const expect = std.testing.expect;
pub fn main() !void {
    std.debug.print("hello world!", .{});
    //Determine which games would have been possible if the bag had been loaded with only
    //12 red cubes, 13 green cubes, and 14 blue cubes. What is the sum of the IDs of those games?

    // read from input

    // put into structure
    // i.e. an array of structs? [{id: 1, blue: 3, red: 1,...}]

    // go through each round and check if the entry for that color is larger than the max

    // if it's not larger for all then it's possible!

    // push that id to the array

    // sum all id's from array.
}

test "put into struct" {
    var round = Round{};
    round.setRed(12);
    try expect(round.getRed() == 12);

    round.setGreen(13);
    try expect(round.getGreen() == 13);

    round.setBlue(14);
    try expect(round.getBlue() == 14);
}
const Round = struct {
    red: u8 = 0,
    green: u8 = 0,
    blue: u8 = 0,

    fn setRed(self: *Round, count: u8) void {
        self.red = count;
    }
    fn getRed(self: *Round) u8 {
        return self.red;
    }

    fn setGreen(self: *Round, count: u8) void {
        self.green = count;
    }
    fn getGreen(self: *Round) u8 {
        return self.green;
    }

    fn setBlue(self: *Round, count: u8) void {
        self.blue = count;
    }
    fn getBlue(self: *Round) u8 {
        return self.blue;
    }
};

test "Create new game" {
    var game = Game{};
    game.setId(0);
    const id = game.getId();

    try expect(id == 0);

    // store results of each round in game
    var round_one = Round{};
    round_one.setRed(1);
    round_one.setGreen(2);
    round_one.setBlue(3);

    game.addRound(round_one);

    const round = game.getRound();

    try expect(round.?.blue == 3);
}

const Game = struct {
    id: u8 = 0,
    round: ?Round = null,
    fn getId(self: *Game) u8 {
        return self.id;
    }
    fn setId(self: *Game, id: u8) void {
        self.id = id;
    }
    fn addRound(self: *Game, round: Round) void {
        self.round = round;
    }
    fn getRound(self: *Game) ?Round {
        return self.round;
    }
};
