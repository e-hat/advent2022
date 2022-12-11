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

fn offsetOf(itemType: u8) usize {
    if (itemType > 'a' and itemType <= 'z') {
        return itemType - 'a';
    } else {
        return itemType - 'A' + 26;
    }
}

fn makeItemTypeBitmask(items: []const u8) u64 {
    var result: u64 = 0;
    for (items) |char| {
        result |= @as(u64, 0x1) << @intCast(u6, offsetOf(char));
    }

    return result;
}

fn priority(itemTypeMask: u64) u32 {
    return @ctz(u64, itemTypeMask) + 1;
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

    var secondElfBuf = std.ArrayList(u8).init(allocator);
    defer secondElfBuf.deinit();
    var thirdElfBuf = std.ArrayList(u8).init(allocator);
    defer thirdElfBuf.deinit();

    var result: u32 = 0;
    while (try lineIter.next()) |firstElf| {
        const secondElf = try lineIter.nextWithArrayList(&secondElfBuf);
        const thirdElf = try lineIter.nextWithArrayList(&thirdElfBuf);

        const firstMask = makeItemTypeBitmask(firstElf);
        const secondMask = makeItemTypeBitmask(secondElf.?);
        const thirdMask = makeItemTypeBitmask(thirdElf.?);

        const inCommon = firstMask & secondMask & thirdMask;
        result += priority(inCommon);
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{d}\n", .{result});
}
