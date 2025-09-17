const std = @import("std");
const testing = std.testing;
const config = @import("../config.zig");

test "Config.init creates default configuration" {
    const cfg = config.Config.init();
    
    try testing.expect(cfg.path.len == 0);
    try testing.expect(cfg.append == true);
    try testing.expect(cfg.bulleted == true);
    try testing.expect(cfg.skip == 0);
    try testing.expect(cfg.depth == 6);
    try testing.expect(cfg.show_help == false);
}

test "Config.validate requires path when help is false" {
    var cfg = config.Config.init();
    
    // Should fail validation without path
    try testing.expectError(error.PathRequired, cfg.validate());
    
    // Should pass with path
    cfg.path = "test.md";
    try cfg.validate();
}

test "Config.validate allows empty path when help is true" {
    var cfg = config.Config.init();
    cfg.show_help = true;
    
    // Should pass validation even without path when help is requested
    try cfg.validate();
}

test "Config.validate checks depth bounds" {
    var cfg = config.Config.init();
    cfg.path = "test.md";
    
    // Should fail with depth 0
    cfg.depth = 0;
    try testing.expectError(error.InvalidDepth, cfg.validate());
    
    // Should fail with depth > 6
    cfg.depth = 7;
    try testing.expectError(error.InvalidDepth, cfg.validate());
    
    // Should pass with valid depths
    cfg.depth = 1;
    try cfg.validate();
    
    cfg.depth = 6;
    try cfg.validate();
}

test "ArgParser.parse handles help flags" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    var parser = config.ArgParser.init(allocator);
    
    // Test short help flag
    const args1 = [_][]const u8{ "toc", "-h" };
    const cfg1 = try parser.parse(&args1);
    try testing.expect(cfg1.show_help == true);
    
    // Test long help flag
    const args2 = [_][]const u8{ "toc", "--help" };
    const cfg2 = try parser.parse(&args2);
    try testing.expect(cfg2.show_help == true);
}

test "ArgParser.parse handles path flags" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    var parser = config.ArgParser.init(allocator);
    
    // Test short path flag
    const args1 = [_][]const u8{ "toc", "-p", "test.md" };
    const cfg1 = try parser.parse(&args1);
    try testing.expectEqualStrings("test.md", cfg1.path);
    
    // Test long path flag
    const args2 = [_][]const u8{ "toc", "--path", "another.md" };
    const cfg2 = try parser.parse(&args2);
    try testing.expectEqualStrings("another.md", cfg2.path);
}

test "ArgParser.parse handles boolean flags" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    var parser = config.ArgParser.init(allocator);
    
    // Test append flag
    const args1 = [_][]const u8{ "toc", "-p", "test.md", "-a", "false" };
    const cfg1 = try parser.parse(&args1);
    try testing.expect(cfg1.append == false);
    
    // Test bulleted flag
    const args2 = [_][]const u8{ "toc", "-p", "test.md", "-b", "false" };
    const cfg2 = try parser.parse(&args2);
    try testing.expect(cfg2.bulleted == false);
}

test "ArgParser.parse handles integer flags" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    var parser = config.ArgParser.init(allocator);
    
    // Test skip flag
    const args1 = [_][]const u8{ "toc", "-p", "test.md", "-s", "2" };
    const cfg1 = try parser.parse(&args1);
    try testing.expect(cfg1.skip == 2);
    
    // Test depth flag
    const args2 = [_][]const u8{ "toc", "-p", "test.md", "-d", "3" };
    const cfg2 = try parser.parse(&args2);
    try testing.expect(cfg2.depth == 3);
}

test "ArgParser.parse handles missing values" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    var parser = config.ArgParser.init(allocator);
    
    // Test missing path value
    const args1 = [_][]const u8{ "toc", "-p" };
    try testing.expectError(error.MissingPathValue, parser.parse(&args1));
    
    // Test missing skip value
    const args2 = [_][]const u8{ "toc", "-p", "test.md", "-s" };
    try testing.expectError(error.MissingSkipValue, parser.parse(&args2));
}

test "ArgParser.parse handles complex argument combinations" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    var parser = config.ArgParser.init(allocator);
    
    const args = [_][]const u8{ 
        "toc", 
        "--path", "complex.md", 
        "--append", "false", 
        "--bulleted", "false", 
        "--skip", "1", 
        "--depth", "4" 
    };
    
    const cfg = try parser.parse(&args);
    
    try testing.expectEqualStrings("complex.md", cfg.path);
    try testing.expect(cfg.append == false);
    try testing.expect(cfg.bulleted == false);
    try testing.expect(cfg.skip == 1);
    try testing.expect(cfg.depth == 4);
    try testing.expect(cfg.show_help == false);
}