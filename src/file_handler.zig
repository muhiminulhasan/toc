const std = @import("std");

/// File handler for reading and writing markdown files
pub const FileHandler = struct {
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{ .allocator = allocator };
    }

    /// Read file content into memory
    pub fn readFile(self: *Self, path: []const u8) ![]const u8 {
        const file = std.fs.cwd().openFile(path, .{}) catch |err| switch (err) {
            error.FileNotFound => {
                std.debug.print("Error: File not found: {s}\n", .{path});
                return err;
            },
            error.AccessDenied => {
                std.debug.print("Error: Access denied: {s}\n", .{path});
                return err;
            },
            else => return err,
        };
        defer file.close();

        const file_size = try file.getEndPos();
        if (file_size > std.math.maxInt(usize)) {
            return error.FileTooLarge;
        }

        const content = try self.allocator.alloc(u8, file_size);
        _ = try file.readAll(content);

        return content;
    }

    /// Write content to file
    pub fn writeFile(self: *Self, path: []const u8, content: []const u8) !void {
        _ = self; // Mark as unused since we don't need self for this operation
        try std.fs.cwd().writeFile(.{ .sub_path = path, .data = content });
    }

    /// Check if file exists
    pub fn fileExists(self: *Self, path: []const u8) bool {
        _ = self;
        std.fs.cwd().access(path, .{}) catch return false;
        return true;
    }

    /// Validate file path and extension
    pub fn validateMarkdownFile(self: *Self, path: []const u8) !void {
        _ = self;

        if (path.len == 0) {
            return error.EmptyPath;
        }

        // Check if path has .md or .markdown extension
        const has_md_ext = std.mem.endsWith(u8, path, ".md");
        const has_markdown_ext = std.mem.endsWith(u8, path, ".markdown");

        if (!has_md_ext and !has_markdown_ext) {
            std.debug.print("Warning: File does not have .md or .markdown extension: {s}\n", .{path});
        }
    }

    /// Create backup of original file
    pub fn createBackup(self: *Self, path: []const u8) !void {
        const backup_path = try std.fmt.allocPrint(self.allocator, "{s}.backup", .{path});
        defer self.allocator.free(backup_path);

        const content = try self.readFile(path);
        defer self.allocator.free(content);

        try self.writeFile(backup_path, content);
        std.debug.print("Backup created: {s}\n", .{backup_path});
    }
};
