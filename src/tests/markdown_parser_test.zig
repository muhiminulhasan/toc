const std = @import("std");
const testing = std.testing;
const markdown_parser = @import("../markdown_parser.zig");

test "Header.init creates header correctly" {
    const header = markdown_parser.Header.init(1, "Test Header", "test-header");
    
    try testing.expect(header.level == 1);
    try testing.expectEqualStrings("Test Header", header.text);
    try testing.expectEqualStrings("test-header", header.anchor);
}

test "MarkdownParser.init creates empty parser" {
    var parser = markdown_parser.MarkdownParser.init(testing.allocator);
    defer parser.deinit();
    
    try testing.expect(parser.headers.items.len == 0);
}

test "MarkdownParser.parse extracts single header" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    var parser = markdown_parser.MarkdownParser.init(allocator);
    defer parser.deinit();
    
    const content = "# Hello World\n\nSome content here.";
    try parser.parse(content);
    
    try testing.expect(parser.headers.items.len == 1);
    try testing.expect(parser.headers.items[0].level == 1);
    try testing.expectEqualStrings("Hello World", parser.headers.items[0].text);
}

test "MarkdownParser.parse extracts multiple headers" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    var parser = markdown_parser.MarkdownParser.init(allocator);
    defer parser.deinit();
    
    const content = 
        \\# Main Title
        \\## Subtitle
        \\### Sub-subtitle
        \\Some content
        \\## Another Subtitle
    ;
    
    try parser.parse(content);
    
    try testing.expect(parser.headers.items.len == 4);
    try testing.expect(parser.headers.items[0].level == 1);
    try testing.expectEqualStrings("Main Title", parser.headers.items[0].text);
    try testing.expect(parser.headers.items[1].level == 2);
    try testing.expectEqualStrings("Subtitle", parser.headers.items[1].text);
    try testing.expect(parser.headers.items[2].level == 3);
    try testing.expectEqualStrings("Sub-subtitle", parser.headers.items[2].text);
    try testing.expect(parser.headers.items[3].level == 2);
    try testing.expectEqualStrings("Another Subtitle", parser.headers.items[3].text);
}

test "MarkdownParser.parse handles headers with different levels" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    var parser = markdown_parser.MarkdownParser.init(allocator);
    defer parser.deinit();
    
    const content = 
        \\# Level 1
        \\## Level 2
        \\### Level 3
        \\#### Level 4
        \\##### Level 5
        \\###### Level 6
    ;
    
    try parser.parse(content);
    
    try testing.expect(parser.headers.items.len == 6);
    for (parser.headers.items, 0..) |header, i| {
        try testing.expect(header.level == i + 1);
    }
}

test "MarkdownParser.parse ignores invalid headers" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    var parser = markdown_parser.MarkdownParser.init(allocator);
    defer parser.deinit();
    
    const content = 
        \\# Valid Header
        \\####### Too many hashes
        \\#
        \\# 
        \\##
        \\## Valid Header 2
        \\Not a header
        \\#NotAHeader
    ;
    
    try parser.parse(content);
    
    try testing.expect(parser.headers.items.len == 2);
    try testing.expectEqualStrings("Valid Header", parser.headers.items[0].text);
    try testing.expectEqualStrings("Valid Header 2", parser.headers.items[1].text);
}

test "MarkdownParser.generateAnchor creates proper anchors" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    var parser = markdown_parser.MarkdownParser.init(allocator);
    defer parser.deinit();
    
    // Test basic anchor generation
    const anchor1 = try parser.generateAnchor("Hello World");
    try testing.expectEqualStrings("hello-world", anchor1);
    
    // Test with special characters
    const anchor2 = try parser.generateAnchor("Hello, World! & More");
    try testing.expectEqualStrings("hello-world-more", anchor2);
    
    // Test with numbers
    const anchor3 = try parser.generateAnchor("Section 1.2.3");
    try testing.expectEqualStrings("section-123", anchor3);
    
    // Test with consecutive spaces/dashes
    const anchor4 = try parser.generateAnchor("Multiple   Spaces--And-Dashes");
    try testing.expectEqualStrings("multiple-spaces-and-dashes", anchor4);
}

test "MarkdownParser.getFilteredHeaders respects skip parameter" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    var parser = markdown_parser.MarkdownParser.init(allocator);
    defer parser.deinit();
    
    const content = 
        \\# Header 1
        \\## Header 2
        \\### Header 3
        \\#### Header 4
    ;
    
    try parser.parse(content);
    
    // Skip first 2 headers
    const filtered = parser.getFilteredHeaders(2, 6);
    defer filtered.deinit();
    
    try testing.expect(filtered.items.len == 2);
    try testing.expectEqualStrings("Header 3", filtered.items[0].text);
    try testing.expectEqualStrings("Header 4", filtered.items[1].text);
}

test "MarkdownParser.getFilteredHeaders respects depth parameter" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    var parser = markdown_parser.MarkdownParser.init(allocator);
    defer parser.deinit();
    
    const content = 
        \\# Header 1
        \\## Header 2
        \\### Header 3
        \\#### Header 4
        \\##### Header 5
        \\###### Header 6
    ;
    
    try parser.parse(content);
    
    // Only include headers up to level 3
    const filtered = parser.getFilteredHeaders(0, 3);
    defer filtered.deinit();
    
    try testing.expect(filtered.items.len == 3);
    try testing.expect(filtered.items[0].level == 1);
    try testing.expect(filtered.items[1].level == 2);
    try testing.expect(filtered.items[2].level == 3);
}

test "MarkdownParser.getFilteredHeaders combines skip and depth" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    var parser = markdown_parser.MarkdownParser.init(allocator);
    defer parser.deinit();
    
    const content = 
        \\# Header 1
        \\## Header 2
        \\### Header 3
        \\#### Header 4
        \\##### Header 5
        \\###### Header 6
    ;
    
    try parser.parse(content);
    
    // Skip first header and only include up to level 4
    const filtered = parser.getFilteredHeaders(1, 4);
    defer filtered.deinit();
    
    try testing.expect(filtered.items.len == 3);
    try testing.expectEqualStrings("Header 2", filtered.items[0].text);
    try testing.expectEqualStrings("Header 3", filtered.items[1].text);
    try testing.expectEqualStrings("Header 4", filtered.items[2].text);
}