const std = @import("std");
const ArrayList = std.ArrayList;
const markdown_parser = @import("markdown_parser.zig");
const Header = markdown_parser.Header;

/// Table of Contents generator
pub const TocGenerator = struct {
    allocator: std.mem.Allocator,
    bulleted: bool,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, bulleted: bool) Self {
        return Self{
            .allocator = allocator,
            .bulleted = bulleted,
        };
    }

    /// Generate TOC string from headers
    pub fn generate(self: *Self, headers: []const Header) ![]const u8 {
        if (headers.len == 0) {
            return error.NoHeaders;
        }

        var toc: ArrayList(u8) = .empty;
        defer toc.deinit(self.allocator);

        var counter: [6]u32 = [_]u32{0} ** 6;

        for (headers) |header| {
            const line = try self.generateLine(header, &counter);
            defer self.allocator.free(line);

            try toc.appendSlice(self.allocator, line);
            try toc.append(self.allocator, '\n');
        }

        return self.allocator.dupe(u8, toc.items);
    }

    /// Generate a single TOC line for a header
    fn generateLine(self: *Self, header: Header, counter: *[6]u32) ![]const u8 {
        const level = header.level - 1; // Convert to 0-based index

        // Reset counters for deeper levels
        var i: usize = level + 1;
        while (i < 6) : (i += 1) {
            counter[i] = 0;
        }

        // Increment counter for current level
        counter[level] += 1;

        var line: ArrayList(u8) = .empty;
        defer line.deinit(self.allocator);

        // Add indentation (4 spaces per level)
        var indent_level: usize = 0;
        while (indent_level < level) : (indent_level += 1) {
            try line.appendSlice(self.allocator, "    ");
        }

        // Add bullet or number
        if (self.bulleted) {
            try line.appendSlice(self.allocator, "- ");
        } else {
            const number_str = try std.fmt.allocPrint(self.allocator, "{}. ", .{counter[level]});
            defer self.allocator.free(number_str);
            try line.appendSlice(self.allocator, number_str);
        }

        // Add link
        try line.append(self.allocator, '[');
        try line.appendSlice(self.allocator, header.text);
        try line.appendSlice(self.allocator, "](#");
        try line.appendSlice(self.allocator, header.anchor);
        try line.append(self.allocator, ')');

        return self.allocator.dupe(u8, line.items);
    }
};

/// TOC insertion helper
pub const TocInserter = struct {
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{ .allocator = allocator };
    }

    /// Insert TOC into markdown content between <!--toc--> and <!--/toc--> markers
    pub fn insertToc(self: *Self, content: []const u8, toc: []const u8) ![]const u8 {
        const start_marker = "<!--toc-->";
        const end_markers = [_][]const u8{ "<!--/toc-->", "<!--end of toc-->", "<!--tocstop-->" };

        const start_pos = std.mem.indexOf(u8, content, start_marker) orelse {
            return error.StartMarkerNotFound;
        };

        var end_pos: ?usize = null;
        for (end_markers) |marker| {
            if (std.mem.indexOf(u8, content[start_pos..], marker)) |pos| {
                end_pos = start_pos + pos + marker.len;
                break;
            }
        }

        if (end_pos == null) {
            // If no end marker found, insert after start marker
            end_pos = start_pos + start_marker.len;
        }

        var result: ArrayList(u8) = .empty;
        defer result.deinit(self.allocator);

        // Add content before start marker
        try result.appendSlice(self.allocator, content[0..start_pos]);

        // Add start marker
        try result.appendSlice(self.allocator, start_marker);
        try result.append(self.allocator, '\n');

        // Add TOC
        try result.appendSlice(self.allocator, toc);

        // Add end marker if it existed
        if (end_pos.? > start_pos + start_marker.len) {
            try result.append(self.allocator, '\n');
            // Find which end marker was used
            for (end_markers) |marker| {
                if (std.mem.indexOf(u8, content[start_pos..end_pos.?], marker)) |_| {
                    try result.appendSlice(self.allocator, marker);
                    break;
                }
            }
        }

        // Add remaining content
        try result.appendSlice(self.allocator, content[end_pos.?..]);

        return self.allocator.dupe(u8, result.items);
    }
};
