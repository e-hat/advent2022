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

    var result: u32 = 0;
    var groupSum: u32 = 0;

    while (try lineIter.next()) |line| {
        if (line.len == 0) {
            result = std.math.max(result, groupSum);
            groupSum = 0;
        } else {
            var calories: u32 = try std.fmt.parseInt(u32, line, 10);

            groupSum += calories;
        }
    }

    result = std.math.max(result, groupSum);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{result});
}
