const std = @import("std");
const toc_app = @import("toc_app.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Get command line arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var runner = toc_app.AppRunner.init(allocator);

    try runner.run(args);
}
