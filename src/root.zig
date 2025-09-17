const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

// Configuration options
pub const Options = struct {
    path: []const u8 = "",
    append: bool = true,
    bulleted: bool = true,
    skip: i32 = 0,
    depth: i32 = 6,
    show_help: bool = false,
};

// Headers map
const headers = std.StaticStringMap(i32).initComptime(.{
    .{ "h1", 0 },
    .{ "h2", 1 },
    .{ "h3", 2 },
    .{ "h4", 3 },
    .{ "h5", 4 },
    .{ "h6", 5 },
});

// Tab string for indentation
const tab = "    ";

// TOC structure
pub const Toc = struct {
    options: Options,
    content: ArrayList([]const u8),
    allocator: Allocator;

    pub fn init(allocator: Allocator) Toc {
        return Toc{
            .options = Options{},
            .content = ArrayList([]const u8).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Toc) void {
        for (self.content.items) |item| {
            self.allocator.free(item);
        }
        self.content.deinit();
    }

    pub fn run(self: *Toc, args: []const []const u8) !void {
        // Parse command line arguments
        try self.parseArgs(args);

        // Show help if requested
        if (self.options.show_help) {
            self.printUsage();
            return;
        }

        // Check if path is provided
        if (self.options.path.len == 0) {
            std.debug.print("ERROR: path flag is missing\n", .{});
            self.printUsage();
            return error.MissingPath;
        }

        // Execute the main logic
        try self.logic();
    }

    fn parseArgs(self: *Toc, args: []const []const u8) !void {
        var i: usize = 0;
        while (i < args.len) : (i += 1) {
            const arg = args[i];

            if (std.mem.eql(u8, arg, "-p") or std.mem.eql(u8, arg, "--path")) {
                i += 1;
                if (i >= args.len) {
                    std.debug.print("ERROR: Missing value for {s}\n", .{arg});
                    return error.MissingValue;
                }
                self.options.path = args[i];
            } else if (std.mem.eql(u8, arg, "-a") or std.mem.eql(u8, arg, "--append")) {
                i += 1;
                if (i >= args.len) {
                    std.debug.print("ERROR: Missing value for {s}\n", .{arg});
                    return error.MissingValue;
                }
                self.options.append = std.mem.eql(u8, args[i], "true") or std.mem.eql(u8, args[i], "1");
            } else if (std.mem.eql(u8, arg, "-b") or std.mem.eql(u8, arg, "--bulleted")) {
                i += 1;
                if (i >= args.len) {
                    std.debug.print("ERROR: Missing value for {s}\n", .{arg});
                    return error.MissingValue;
                }
                self.options.bulleted = std.mem.eql(u8, args[i], "true") or std.mem.eql(u8, args[i], "1");
            } else if (std.mem.eql(u8, arg, "-s") or std.mem.eql(u8, arg, "--skip")) {
                i += 1;
                if (i >= args.len) {
                    std.debug.print("ERROR: Missing value for {s}\n", .{arg});
                    return error.MissingValue;
                }
                self.options.skip = try std.fmt.parseInt(i32, args[i], 10);
            } else if (std.mem.eql(u8, arg, "-d") or std.mem.eql(u8, arg, "--depth")) {
                i += 1;
                if (i >= args.len) {
                    std.debug.print("ERROR: Missing value for {s}\n", .{arg});
                    return error.MissingValue;
                }
                self.options.depth = try std.fmt.parseInt(i32, args[i], 10);
            } else if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
                self.options.show_help = true;
            } else {
                std.debug.print("ERROR: Unknown argument: {s}\n", .{arg});
                return error.UnknownArgument;
            }
        }
    }

    fn printUsage(self: *Toc) void {
        _ = self;
        const usage =
            \\Usage: toc [options]
            \\Options:
            \\    -p, --path      <path>   Path for the markdown file.                               [REQUIRED]
            \\    -a, --append    <bool>   Append toc after <!--toc-->, or write to stdout.          [Default: true]
            \\    -b, --bulleted  <bool>   Write as bulleted, or write as numbered list.             [Default: true] 
            \\    -s, --skip      <int>    Skip the first given number of headers.                   [Default: 0]
            \\    -d, --depth     <int>    Set the number of maximum heading level to be included.   [Default: 6]
            \\    -h, --help               Show this message and exit.
            \\
        ;
        std.debug.print("{s}", .{usage});
    }

    fn logic(self: *Toc) !void {
        // Read the file
        const file_content = try std.fs.cwd().readFileAlloc(self.allocator, self.options.path, 1024 * 1024); // 1MB limit
        defer self.allocator.free(file_content);

        // Parse markdown and generate TOC
        try self.parseMarkdown(file_content);

        // Output based on options
        if (!self.options.append) {
            try self.printToStdout();
            return;
        }

        // Write TOC to file
        try self.writeToFile(file_content);
        std.debug.print("✔ Table of contents generated successfully\n", .{});
    }

    fn parseMarkdown(self: *Toc, content: []const u8) !void {
        var lines = std.mem.split(u8, content, "\n");
        while (lines.next()) |line| {
            // Check if line is a header (starts with #)
            if (line.len > 0 and line[0] == '#') {
                // Count number of # to determine header level
                var level: i32 = 0;
                for (line) |char| {
                    if (char == '#') {
                        level += 1;
                    } else {
                        break;
                    }
                }

                // Skip if level is outside depth range
                if (level >= 1 and level <= 6 and level > self.options.skip and level <= self.options.depth) {
                    // Extract header text (skip # and spaces)
                    var text_start: usize = 0;
                    for (line, 0..) |char, idx| {
                        if (char != '#' and char != ' ') {
                            text_start = idx;
                            break;
                        }
                    }

                    if (text_start < line.len) {
                        const header_text = line[text_start..];

                        // Create anchor link (lowercase, replace spaces with -, remove special chars)
                        var anchor = ArrayList(u8).init(self.allocator);
                        defer anchor.deinit();

                        for (header_text) |char| {
                            if (char == ' ') {
                                try anchor.append('-');
                            } else if (char >= 'A' and char <= 'Z') {
                                try anchor.append(char + 32); // Convert to lowercase
                            } else if ((char >= 'a' and char <= 'z') or (char >= '0' and char <= '9') or char == '-' or char == '_') {
                                try anchor.append(char);
                            }
                            // Skip special characters
                        }

                        // Generate TOC entry
                        const indent_level = level - 1 - self.options.skip;
                        const indent = try self.allocator.alloc(u8, @intCast(indent_level * 4));
                        @memset(indent, ' ');

                        const delimiter = if (self.options.bulleted)
                            if (level > 1) "*" else "-"
                        else
                            "1.";

                        const entry = try std.fmt.allocPrint(self.allocator, "{s}{s} [{s}](#{s})\n", .{ indent, delimiter, header_text, anchor.items });

                        self.allocator.free(indent);
                        try self.content.append(entry);
                    }
                }
            }
        }
    }

    fn printToStdout(self: *Toc) !void {
        for (self.content.items) |item| {
            try std.io.getStdOut().writer().print("{s}", .{item});
        }
    }

    fn writeToFile(self: *Toc, original_content: []const u8) !void {
        // Find <!--toc--> marker
        const start_marker = "<!--toc-->";
        const end_marker = "<!-- tocstop -->";

        const start_pos = std.mem.indexOf(u8, original_content, start_marker);
        if (start_pos == null) {
            std.debug.print("ERROR: toc path is missing, add '<!--toc-->' to your markdown\n", .{});
            return error.MissingTocMarker;
        }

        const start_idx = start_pos.? + start_marker.len;

        // Find end marker if it exists
        var end_idx = start_idx;
        const end_pos = std.mem.indexOf(u8, original_content, end_marker);
        if (end_pos) |pos| {
            end_idx = pos;
        }

        // Build new content
        var new_content = ArrayList(u8).init(self.allocator);
        defer new_content.deinit();

        // Add content before <!--toc-->
        try new_content.appendSlice(original_content[0..start_pos.?]);
        try new_content.appendSlice(start_marker);
        try new_content.append('\n');

        // Add TOC content
        for (self.content.items) |item| {
            try new_content.appendSlice(item);
        }

        // Add end marker and content after
        try new_content.appendSlice("\n");
        try new_content.appendSlice(end_marker);

        if (end_pos) |pos| {
            try new_content.appendSlice(original_content[pos + end_marker.len ..]);
        } else {
            try new_content.appendSlice(original_content[start_idx..]);
        }

        // Write to file
        try std.fs.cwd().writeFile(self.options.path, new_content.items);
    }
};
