const std = @import("std");
const assert = std.debug.assert;

const FileLineIterator = struct {
    line: *std.ArrayList(u8),
    reader: *const std.fs.File.Reader,
    fn next(self: *FileLineIterator) !?[]const u8 {
        self.line.shrinkRetainingCapacity(0);
        var index: usize = 0;
        while (true) {
            const byte = self.reader.readByte() catch |err| switch (err) {
                error.EndOfStream => {
                    if (index == 0) {
                        return null;
                    } else {
                        return self.line.items;
                    }
                },
                else => |e| return e,
            };

            if (byte == '\n') return self.line.items;
            try self.line.append(byte);
            index += 1;
        }
    }
};

const Move = enum { rock, paper, scissors };
const GameResult = enum { win, lose, draw };
const MoveParseError = error{MoveParseError};
const GameResultParseError = error{GameResultParseError};

fn getMove(code: u8) MoveParseError!Move {
    return switch (code) {
        'A' => Move.rock,
        'B' => Move.paper,
        'C' => Move.scissors,
        else => MoveParseError.MoveParseError,
    };
}

fn getResult(code: u8) GameResultParseError!GameResult {
    return switch (code) {
        'X' => GameResult.lose,
        'Y' => GameResult.draw,
        'Z' => GameResult.win,
        else => GameResultParseError.GameResultParseError,
    };
}

fn calculateMyMove(move: Move, endResult: GameResult) Move {
    return switch (endResult) {
        GameResult.draw => move,
        GameResult.win => switch (move) {
            Move.rock => Move.paper,
            Move.paper => Move.scissors,
            Move.scissors => Move.rock,
        },
        GameResult.lose => switch (move) {
            Move.rock => Move.scissors,
            Move.paper => Move.rock,
            Move.scissors => Move.paper,
        },
    };
}

pub fn main() anyerror!void {
    var file = try std.fs.cwd().openFile("data/input.txt", .{ .read = true });
    defer file.close();
    const reader = file.reader();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var lineBuf = std.ArrayList(u8).init(allocator);
    defer lineBuf.deinit();

    var lineIter = FileLineIterator{
        .line = &lineBuf,
        .reader = &reader,
    };

    var totalScore: u32 = 0;

    while (try lineIter.next()) |line| {
        assert(line.len == 3);

        const theirMove = try getMove(line[0]);
        const myMove = calculateMyMove(theirMove, try getResult(line[2]));

        const roundScore: u32 = switch (myMove) {
            Move.rock => 1 + @as(u32, switch (theirMove) {
                Move.rock => 3,
                Move.paper => 0,
                Move.scissors => 6,
            }),
            Move.paper => 2 + @as(u32, switch (theirMove) {
                Move.rock => 6,
                Move.paper => 3,
                Move.scissors => 0,
            }),
            Move.scissors => 3 + @as(u32, switch (theirMove) {
                Move.rock => 0,
                Move.paper => 6,
                Move.scissors => 3,
            }),
        };

        totalScore += roundScore;
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{totalScore});
}
