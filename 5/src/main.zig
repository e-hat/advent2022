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

    var stackingsStrings = std.ArrayList(std.ArrayList(u8)).init(allocator);
    defer {
        for (stackingsStrings.items) |string| {
            string.deinit();
        }
        stackingsStrings.deinit();
    }

    // record all of the initial stack states
    while (try lineIter.next()) |line| {
        if (line.len == 0) break;

        var newString = std.ArrayList(u8).init(allocator);
        try newString.appendSlice(line);
        try stackingsStrings.append(newString);
    }

    // get the last "stack label". This is equal to the number of stacks
    var stackLabelsIter = std.mem.tokenize(u8, stackingsStrings.items[stackingsStrings.items.len - 1].items, " ");
    var lastNumber: usize = 0;
    while (stackLabelsIter.next()) |label| {
        lastNumber = try std.fmt.parseUnsigned(usize, label, 10);
    }

    var stacks = std.ArrayList(std.ArrayList(u8)).init(allocator);
    defer {
        for (stacks.items) |stack| {
            stack.deinit();
        }
        stacks.deinit();
    }

    // create N empty stacks, however many required for the problem
    while (lastNumber > 0) : (lastNumber -= 1) {
        var newStack = std.ArrayList(u8).init(allocator);
        try stacks.append(newStack);
    }

    // Record the state of each stack, going from bottom to top to make this O(N) instead of O(N^2)
    // by appending to the ArrayList
    var lineIndex: isize = @intCast(isize, stackingsStrings.items.len - 2);
    while (lineIndex >= 0) : (lineIndex -= 1) {
        const line = stackingsStrings.items[@intCast(usize, lineIndex)];
        var stackIndex: usize = 0;
        var charIndex: usize = 0;
        while (charIndex < line.items.len) {
            const triplet = line.items[charIndex .. charIndex + 3];
            if (triplet[0] == '[') {
                try stacks.items[stackIndex].append(line.items[charIndex + 1]);
            }

            charIndex += 4;
            stackIndex += 1;
        }
    }

    // Go through every "move" command
    while (try lineIter.next()) |line| {
        // parse out the number of boxes, the source stack label, and the destination stack label
        var wordsIter = std.mem.tokenize(u8, line, " ");
        _ = wordsIter.next();
        const count = try std.fmt.parseUnsigned(usize, wordsIter.next().?, 10);
        _ = wordsIter.next();
        const src = try std.fmt.parseUnsigned(usize, wordsIter.next().?, 10);
        _ = wordsIter.next();
        const dst = try std.fmt.parseInt(usize, wordsIter.next().?, 10);

        var i: usize = 0;
        var srcStack = &stacks.items[src - 1];
        var dstStack = &stacks.items[dst - 1];
        // Attach this chunk of items to the back of the destination stack
        while (i < count) : (i += 1) {
            try dstStack.append(srcStack.items[srcStack.items.len - count + i]);
        }

        // Pop all of them off the source stack
        while (i > 0) : (i -= 1) {
            _ = srcStack.pop();
        }
    }

    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();

    // Record the top item in each stack
    for (stacks.items) |stack| {
        try result.append(stack.items[stack.items.len - 1]);
    }

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{s}\n", .{result.items});
}
