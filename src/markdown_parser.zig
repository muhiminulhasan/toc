const std = @import("std");
const ArrayList = std.ArrayList;

/// Represents a markdown header
pub const Header = struct {
    level: u8,
    text: []const u8,
    anchor: []const u8,

    const Self = @This();

    pub fn init(level: u8, text: []const u8, anchor: []const u8) Self {
        return Self{
            .level = level,
            .text = text,
            .anchor = anchor,
        };
    }

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        allocator.free(self.text);
        allocator.free(self.anchor);
    }
};

/// Markdown parser interface
pub const MarkdownParser = struct {
    allocator: std.mem.Allocator,
    headers: ArrayList(Header),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
            .headers = .empty,
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.headers.items) |*header| {
            header.deinit(self.allocator);
        }
        self.headers.deinit(self.allocator);
    }

    /// Parse markdown content and extract headers
    pub fn parse(self: *Self, content: []const u8) !void {
        var lines = std.mem.splitSequence(u8, content, "\n");
        
        while (lines.next()) |line| {
            const trimmed = std.mem.trim(u8, line, " \t\r");
            if (trimmed.len == 0) continue;
            
            if (trimmed[0] == '#') {
                try self.parseHeader(trimmed);
            }
        }
    }

    /// Parse a single header line
    fn parseHeader(self: *Self, line: []const u8) !void {
        var level: u8 = 0;
        var i: usize = 0;
        
        // Count the number of '#' characters
        while (i < line.len and line[i] == '#' and level < 6) {
            level += 1;
            i += 1;
        }
        
        if (level == 0 or i >= line.len) return;
        
        // Skip whitespace after '#'
        while (i < line.len and (line[i] == ' ' or line[i] == '\t')) {
            i += 1;
        }
        
        if (i >= line.len) return;
        
        const text = std.mem.trim(u8, line[i..], " \t\r");
        if (text.len == 0) return;
        
        // Create a copy of the text
        const text_copy = try self.allocator.dupe(u8, text);
        
        // Generate anchor from text
        const anchor = try self.generateAnchor(text);
        
        const header = Header.init(level, text_copy, anchor);
        try self.headers.append(self.allocator, header);
    }

    /// Generate anchor link from header text
    fn generateAnchor(self: *Self, text: []const u8) ![]const u8 {
        var anchor: ArrayList(u8) = .empty;
        defer anchor.deinit(self.allocator);
        
        for (text) |char| {
            switch (char) {
                'A'...'Z' => try anchor.append(self.allocator, char + 32), // Convert to lowercase
                'a'...'z', '0'...'9' => try anchor.append(self.allocator, char),
                ' ', '\t', '-', '_' => try anchor.append(self.allocator, '-'),
                else => {}, // Skip other characters
            }
        }
        
        // Remove consecutive dashes and trim
        var result: ArrayList(u8) = .empty;
        defer result.deinit(self.allocator);
        
        var prev_dash = false;
        for (anchor.items) |char| {
            if (char == '-') {
                if (!prev_dash) {
                    try result.append(self.allocator, char);
                    prev_dash = true;
                }
            } else {
                try result.append(self.allocator, char);
                prev_dash = false;
            }
        }
        
        // Trim leading and trailing dashes
        var start: usize = 0;
        var end: usize = result.items.len;
        
        while (start < end and result.items[start] == '-') start += 1;
        while (end > start and result.items[end - 1] == '-') end -= 1;
        
        return self.allocator.dupe(u8, result.items[start..end]);
    }

    /// Get headers within specified depth range, skipping the first 'skip' headers
    pub fn getFilteredHeaders(self: *const Self, skip: u32, max_depth: u32) ArrayList(Header) {
        var filtered: ArrayList(Header) = .empty;
        
        var skipped: u32 = 0;
        for (self.headers.items) |header| {
            if (header.level > max_depth) continue;
            
            if (skipped < skip) {
                skipped += 1;
                continue;
            }
            
            filtered.append(self.allocator, header) catch continue;
        }
        
        return filtered;
    }
};