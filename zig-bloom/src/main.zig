const std = @import("std");
const hash = std.hash;

const seeds = [_]u32{
    0xc70f6907,
    0xc15a9323,
    0xc0414444,
};

const HashIter = struct {
    iteration: usize = 0,
    item: []const u8,
    len: usize,

    fn next(self: *@This()) ?usize {
        if (self.iteration >= 3) return null;
        const h = hash.Murmur3_32.hashWithSeed(self.item, seeds[self.iteration]);
        self.iteration += 1;
        return h % self.len;
    }
};

const BloomFilter = struct {
    items: []bool,

    pub fn init(allocator: std.mem.Allocator, size: usize) !BloomFilter {
        return BloomFilter{
            .items = try allocator.alloc(bool, size),
        };
    }

    pub fn deinit(self: *BloomFilter, allocator: std.mem.Allocator) void {
        allocator.free(self.items);
    }

    pub fn add(self: *BloomFilter, item: []const u8) void {
        var h = self.hashes(item);
        while (h.next()) |ha| {
            self.items[ha] = true;
        }
    }

    pub fn check(self: *BloomFilter, item: []const u8) bool {
        var h = self.hashes(item);
        while (h.next()) |ha| {
            if (!self.items[ha]) {
                return false;
            }
        }

        return true;
    }

    fn hashes(self: *BloomFilter, item: []const u8) HashIter {
        return HashIter{
            .iteration = 0,
            .item = item,
            .len = self.items.len,
        };
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    var bloom = try BloomFilter.init(allocator, 128);
    defer bloom.deinit(allocator);
    bloom.add("Brad");
    std.debug.print("{any}\n", .{bloom.check("Brad")});
    std.debug.print("{any}\n", .{bloom.check("Jake")});
    bloom.add("Jake");
    std.debug.print("{any}\n", .{bloom.check("Jake")});
}
