const std = @import("std");

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

    fn nextWithArrayList(self: *FileLineIterator, buf: *std.ArrayList(u8)) !?[]const u8 {
        buf.shrinkRetainingCapacity(0);

        var lineIter = FileLineIterator{
            .line = buf,
            .reader = self.reader,
        };

        return lineIter.next();
    }
};

fn contains(x1: u32, y1: u32, x2: u32, y2: u32) bool {
    return x1 <= x2 and y1 >= y2;
}

fn overlaps(x1: u32, y1: u32, x2: u32, y2: u32) bool {
    return (x1 <= y2 and y1 >= x2);
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

    var result: u32 = 0;
    while (try lineIter.next()) |line| {
        var rangeIter = std.mem.tokenize(u8, line, ",");
        const firstRangeStr = rangeIter.next();
        const secondRangeStr = rangeIter.next();

        var firstRangeIter = std.mem.tokenize(u8, firstRangeStr.?, "-");
        var secondRangeIter = std.mem.tokenize(u8, secondRangeStr.?, "-");

        const firstRangeLoStr = firstRangeIter.next();
        const firstRangeLo = try std.fmt.parseUnsigned(u32, firstRangeLoStr.?, 10);
        const firstRangeHiStr = firstRangeIter.next();
        const firstRangeHi = try std.fmt.parseUnsigned(u32, firstRangeHiStr.?, 10);

        const secondRangeLoStr = secondRangeIter.next();
        const secondRangeLo = try std.fmt.parseUnsigned(u32, secondRangeLoStr.?, 10);
        const secondRangeHiStr = secondRangeIter.next();
        const secondRangeHi = try std.fmt.parseUnsigned(u32, secondRangeHiStr.?, 10);

        if (overlaps(firstRangeLo, firstRangeHi, secondRangeLo, secondRangeHi)) {
            result += 1;
        }
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{result});
}
