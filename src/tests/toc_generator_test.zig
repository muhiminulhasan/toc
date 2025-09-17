const std = @import("std");
const testing = std.testing;
const toc_generator = @import("../toc_generator.zig");
const markdown_parser = @import("../markdown_parser.zig");

test "TocGenerator.init creates generator with correct settings" {
    const generator_bulleted = toc_generator.TocGenerator.init(testing.allocator, true);
    try testing.expect(generator_bulleted.bulleted == true);

    const generator_numbered = toc_generator.TocGenerator.init(testing.allocator, false);
    try testing.expect(generator_numbered.bulleted == false);
}

test "TocGenerator.generate creates bulleted TOC" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var generator = toc_generator.TocGenerator.init(allocator, true);

    const headers = [_]markdown_parser.Header{
        markdown_parser.Header.init(1, "Header 1", "header-1"),
        markdown_parser.Header.init(2, "Header 2", "header-2"),
        markdown_parser.Header.init(3, "Header 3", "header-3"),
    };

    const toc = try generator.generate(&headers);
    defer allocator.free(toc);

    const expected =
        \\- [Header 1](#header-1)
        \\    - [Header 2](#header-2)
        \\        - [Header 3](#header-3)
        \\
    ;

    try testing.expectEqualStrings(expected, toc);
}

test "TocGenerator.generate creates numbered TOC" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var generator = toc_generator.TocGenerator.init(allocator, false);

    const headers = [_]markdown_parser.Header{
        markdown_parser.Header.init(1, "Header 1", "header-1"),
        markdown_parser.Header.init(2, "Header 2", "header-2"),
        markdown_parser.Header.init(1, "Header 3", "header-3"),
        markdown_parser.Header.init(2, "Header 4", "header-4"),
    };

    const toc = try generator.generate(&headers);
    defer allocator.free(toc);

    const expected =
        \\1. [Header 1](#header-1)
        \\    1. [Header 2](#header-2)
        \\2. [Header 3](#header-3)
        \\    1. [Header 4](#header-4)
        \\
    ;

    try testing.expectEqualStrings(expected, toc);
}

test "TocGenerator.generate handles complex nesting" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var generator = toc_generator.TocGenerator.init(allocator, true);

    const headers = [_]markdown_parser.Header{
        markdown_parser.Header.init(1, "Main", "main"),
        markdown_parser.Header.init(2, "Sub 1", "sub-1"),
        markdown_parser.Header.init(3, "Sub Sub 1", "sub-sub-1"),
        markdown_parser.Header.init(3, "Sub Sub 2", "sub-sub-2"),
        markdown_parser.Header.init(2, "Sub 2", "sub-2"),
        markdown_parser.Header.init(4, "Deep", "deep"),
    };

    const toc = try generator.generate(&headers);
    defer allocator.free(toc);

    const expected =
        \\- [Main](#main)
        \\    - [Sub 1](#sub-1)
        \\        - [Sub Sub 1](#sub-sub-1)
        \\        - [Sub Sub 2](#sub-sub-2)
        \\    - [Sub 2](#sub-2)
        \\            - [Deep](#deep)
        \\
    ;

    try testing.expectEqualStrings(expected, toc);
}

test "TocGenerator.generate fails with empty headers" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var generator = toc_generator.TocGenerator.init(allocator, true);

    const headers: []const markdown_parser.Header = &[_]markdown_parser.Header{};

    try testing.expectError(error.NoHeaders, generator.generate(headers));
}

test "TocInserter.init creates inserter" {
    const inserter = toc_generator.TocInserter.init(testing.allocator);
    try testing.expect(inserter.allocator.ptr == testing.allocator.ptr);
}

test "TocInserter.insertToc inserts between markers" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var inserter = toc_generator.TocInserter.init(allocator);

    const content =
        \\# My Document
        \\
        \\<!--toc-->
        \\<!--/toc-->
        \\
        \\## Section 1
        \\Content here.
    ;

    const toc = "- [Section 1](#section-1)";

    const result = try inserter.insertToc(content, toc);
    defer allocator.free(result);

    const expected =
        \\# My Document
        \\
        \\<!--toc-->
        \\- [Section 1](#section-1)
        \\<!--/toc-->
        \\
        \\## Section 1
        \\Content here.
    ;

    try testing.expectEqualStrings(expected, result);
}

test "TocInserter.insertToc handles different end markers" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var inserter = toc_generator.TocInserter.init(allocator);

    // Test with <!--end of toc--> marker
    const content1 =
        \\<!--toc-->
        \\<!--end of toc-->
    ;

    const toc = "- [Test](#test)";

    const result1 = try inserter.insertToc(content1, toc);
    defer allocator.free(result1);

    try testing.expect(std.mem.indexOf(u8, result1, "<!--end of toc-->") != null);

    // Test with <!--tocstop--> marker
    const content2 =
        \\<!--toc-->
        \\<!--tocstop-->
    ;

    const result2 = try inserter.insertToc(content2, toc);
    defer allocator.free(result2);

    try testing.expect(std.mem.indexOf(u8, result2, "<!--tocstop-->") != null);
}

test "TocInserter.insertToc handles missing end marker" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var inserter = toc_generator.TocInserter.init(allocator);

    const content =
        \\# Document
        \\<!--toc-->
        \\## Section
    ;

    const toc = "- [Section](#section)";

    const result = try inserter.insertToc(content, toc);
    defer allocator.free(result);

    const expected =
        \\# Document
        \\<!--toc-->
        \\- [Section](#section)
        \\## Section
    ;

    try testing.expectEqualStrings(expected, result);
}

test "TocInserter.insertToc fails without start marker" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var inserter = toc_generator.TocInserter.init(allocator);

    const content =
        \\# Document
        \\## Section
    ;

    const toc = "- [Section](#section)";

    try testing.expectError(error.StartMarkerNotFound, inserter.insertToc(content, toc));
}

test "TocInserter.insertToc replaces existing TOC" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var inserter = toc_generator.TocInserter.init(allocator);

    const content =
        \\<!--toc-->
        \\- [Old Section](#old-section)
        \\<!--/toc-->
        \\## New Section
    ;

    const toc = "- [New Section](#new-section)";

    const result = try inserter.insertToc(content, toc);
    defer allocator.free(result);

    try testing.expect(std.mem.indexOf(u8, result, "Old Section") == null);
    try testing.expect(std.mem.indexOf(u8, result, "New Section") != null);
}
