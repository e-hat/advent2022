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
};

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

    const lineOption = try lineIter.next();
    const line = lineOption.?;

    const headerLength = 14;
    var history: []u8 = try allocator.alloc(u8, headerLength);
    defer allocator.free(history);
    std.mem.copy(u8, history, line[0..headerLength]);
    for (line[headerLength..]) |char, index| {
        var seenMask = @as(u32, 0);
        for (history) |historyChar| {
            seenMask |= @as(u32, 1) << @intCast(u5, historyChar - 'a');
        }

        if (@popCount(u32, seenMask) == history.len) {
            const stdout = std.io.getStdOut().writer();
            try stdout.print("{d}\n", .{index + headerLength});
            return;
        }

        for (history[0 .. history.len - 1]) |_, i| {
            history[i] = history[i + 1];
        }

        history[history.len - 1] = char;
    }
}
