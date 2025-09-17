const std = @import("std");
const testing = std.testing;
const file_handler = @import("../file_handler.zig");

test "FileHandler.init creates handler" {
    const handler = file_handler.FileHandler.init(testing.allocator);
    try testing.expect(handler.allocator.ptr == testing.allocator.ptr);
}

test "FileHandler.validateMarkdownFile accepts valid extensions" {
    var handler = file_handler.FileHandler.init(testing.allocator);
    
    // Should not error for .md files
    try handler.validateMarkdownFile("test.md");
    try handler.validateMarkdownFile("path/to/file.md");
    
    // Should not error for .markdown files
    try handler.validateMarkdownFile("test.markdown");
    try handler.validateMarkdownFile("path/to/file.markdown");
}

test "FileHandler.validateMarkdownFile warns for invalid extensions" {
    var handler = file_handler.FileHandler.init(testing.allocator);
    
    // Should still pass but print warning (we can't easily test the warning output)
    try handler.validateMarkdownFile("test.txt");
    try handler.validateMarkdownFile("README");
    try handler.validateMarkdownFile("file.html");
}

test "FileHandler.validateMarkdownFile rejects empty path" {
    var handler = file_handler.FileHandler.init(testing.allocator);
    
    try testing.expectError(error.EmptyPath, handler.validateMarkdownFile(""));
}

test "FileHandler.fileExists returns false for non-existent files" {
    var handler = file_handler.FileHandler.init(testing.allocator);
    
    try testing.expect(!handler.fileExists("non_existent_file_12345.md"));
    try testing.expect(!handler.fileExists("path/that/does/not/exist.md"));
}

test "FileHandler.readFile and writeFile work together" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    var handler = file_handler.FileHandler.init(allocator);
    
    const test_content = "# Test Header\n\nThis is test content.";
    const test_file = "test_temp_file.md";
    
    // Clean up any existing test file
    std.fs.cwd().deleteFile(test_file) catch {};
    
    // Write content to file
    try handler.writeFile(test_file, test_content);
    
    // Verify file exists
    try testing.expect(handler.fileExists(test_file));
    
    // Read content back
    const read_content = try handler.readFile(test_file);
    defer allocator.free(read_content);
    
    // Verify content matches
    try testing.expectEqualStrings(test_content, read_content);
    
    // Clean up
    std.fs.cwd().deleteFile(test_file) catch {};
}

test "FileHandler.readFile handles non-existent files" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    var handler = file_handler.FileHandler.init(allocator);
    
    try testing.expectError(error.FileNotFound, handler.readFile("non_existent_file_12345.md"));
}

test "FileHandler.createBackup creates backup file" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    var handler = file_handler.FileHandler.init(allocator);
    
    const test_content = "# Original Content\n\nThis is the original file.";
    const test_file = "test_backup_original.md";
    const backup_file = "test_backup_original.md.backup";
    
    // Clean up any existing files
    std.fs.cwd().deleteFile(test_file) catch {};
    std.fs.cwd().deleteFile(backup_file) catch {};
    
    // Create original file
    try handler.writeFile(test_file, test_content);
    
    // Create backup
    try handler.createBackup(test_file);
    
    // Verify backup exists
    try testing.expect(handler.fileExists(backup_file));
    
    // Verify backup content matches original
    const backup_content = try handler.readFile(backup_file);
    defer allocator.free(backup_content);
    try testing.expectEqualStrings(test_content, backup_content);
    
    // Clean up
    std.fs.cwd().deleteFile(test_file) catch {};
    std.fs.cwd().deleteFile(backup_file) catch {};
}

test "FileHandler.writeFile overwrites existing files" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    var handler = file_handler.FileHandler.init(allocator);
    
    const original_content = "# Original Content";
    const new_content = "# New Content\n\nThis is updated.";
    const test_file = "test_overwrite.md";
    
    // Clean up any existing file
    std.fs.cwd().deleteFile(test_file) catch {};
    
    // Write original content
    try handler.writeFile(test_file, original_content);
    
    // Verify original content
    const read_original = try handler.readFile(test_file);
    defer allocator.free(read_original);
    try testing.expectEqualStrings(original_content, read_original);
    
    // Overwrite with new content
    try handler.writeFile(test_file, new_content);
    
    // Verify new content
    const read_new = try handler.readFile(test_file);
    defer allocator.free(read_new);
    try testing.expectEqualStrings(new_content, read_new);
    
    // Clean up
    std.fs.cwd().deleteFile(test_file) catch {};
}

test "FileHandler handles empty files" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    var handler = file_handler.FileHandler.init(allocator);
    
    const empty_content = "";
    const test_file = "test_empty.md";
    
    // Clean up any existing file
    std.fs.cwd().deleteFile(test_file) catch {};
    
    // Write empty content
    try handler.writeFile(test_file, empty_content);
    
    // Read empty content back
    const read_content = try handler.readFile(test_file);
    defer allocator.free(read_content);
    
    try testing.expectEqualStrings(empty_content, read_content);
    try testing.expect(read_content.len == 0);
    
    // Clean up
    std.fs.cwd().deleteFile(test_file) catch {};
}