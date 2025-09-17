const std = @import("std");
const config = @import("config.zig");
const markdown_parser = @import("markdown_parser.zig");
const toc_generator = @import("toc_generator.zig");
const file_handler = @import("file_handler.zig");

const Config = config.Config;
const ArgParser = config.ArgParser;
const MarkdownParser = markdown_parser.MarkdownParser;
const TocGenerator = toc_generator.TocGenerator;
const TocInserter = toc_generator.TocInserter;
const FileHandler = file_handler.FileHandler;

/// Main TOC application
pub const TocApp = struct {
    allocator: std.mem.Allocator,
    config: Config,
    parser: MarkdownParser,
    generator: TocGenerator,
    inserter: TocInserter,
    file_handler: FileHandler,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, app_config: Config) Self {
        return Self{
            .allocator = allocator,
            .config = app_config,
            .parser = MarkdownParser.init(allocator),
            .generator = TocGenerator.init(allocator, app_config.bulleted),
            .inserter = TocInserter.init(allocator),
            .file_handler = FileHandler.init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.parser.deinit();
    }

    /// Run the TOC generation process
    pub fn run(self: *Self) !void {
        // Validate the markdown file
        try self.file_handler.validateMarkdownFile(self.config.path);

        if (!self.file_handler.fileExists(self.config.path)) {
            std.debug.print("Error: File does not exist: {s}\n", .{self.config.path});
            return error.FileNotFound;
        }

        // Read the markdown file
        const content = self.file_handler.readFile(self.config.path) catch |err| {
            std.debug.print("Error reading file: {s}\n", .{self.config.path});
            return err;
        };
        defer self.allocator.free(content);

        // Parse headers from markdown
        try self.parser.parse(content);

        // Get filtered headers based on skip and depth settings
        var filtered_headers = self.parser.getFilteredHeaders(self.config.skip, self.config.depth);
        defer filtered_headers.deinit(self.allocator);

        if (filtered_headers.items.len == 0) {
            if (self.config.skip > 0) {
                std.debug.print("Error: Skip value ({}) is larger than the number of available headers\n", .{self.config.skip});
            } else {
                std.debug.print("Error: No headers found in the markdown file\n", .{});
            }
            return error.NoHeaders;
        }

        // Generate TOC
        const toc = self.generator.generate(filtered_headers.items) catch |err| {
            std.debug.print("Error generating TOC: {}\n", .{err});
            return err;
        };
        defer self.allocator.free(toc);

        // Handle output based on append setting
        if (self.config.append) {
            try self.appendToFile(content, toc);
        } else {
            try self.printToStdout(toc);
        }
    }

    /// Append TOC to the original file
    fn appendToFile(self: *Self, content: []const u8, toc: []const u8) !void {
        // Create backup before modifying
        self.file_handler.createBackup(self.config.path) catch |err| {
            std.debug.print("Warning: Could not create backup: {}\n", .{err});
        };

        // Insert TOC into content
        const updated_content = self.inserter.insertToc(content, toc) catch |err| switch (err) {
            error.StartMarkerNotFound => {
                std.debug.print("Error: <!--toc--> marker not found in file. Please add it where you want the TOC to be inserted.\n", .{});
                return err;
            },
            else => return err,
        };
        defer self.allocator.free(updated_content);

        // Write updated content back to file
        try self.file_handler.writeFile(self.config.path, updated_content);
        
        // Success message
        std.debug.print("✓ Table of contents generated successfully\n", .{});
    }

    /// Print TOC to stdout
    fn printToStdout(self: *Self, toc: []const u8) !void {
        _ = self;
        std.debug.print("{s}", .{toc});
    }
};

/// Application runner - handles command line parsing and error handling
pub const AppRunner = struct {
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{ .allocator = allocator };
    }

    /// Run the application with command line arguments
    pub fn run(self: *Self, args: []const []const u8) !void {
        var arg_parser = ArgParser.init(self.allocator);
        
        const app_config = arg_parser.parse(args) catch |err| switch (err) {
            error.PathRequired => {
                std.debug.print("Error: Path flag is required\n\n", .{});
                ArgParser.showHelp();
                return;
            },
            error.InvalidDepth => {
                std.debug.print("Error: Depth must be between 1 and 6\n\n", .{});
                ArgParser.showHelp();
                return;
            },
            error.MissingPathValue,
            error.MissingAppendValue,
            error.MissingBulletedValue,
            error.MissingSkipValue,
            error.MissingDepthValue => {
                std.debug.print("Error: Missing value for argument\n\n", .{});
                ArgParser.showHelp();
                return;
            },
            else => {
                std.debug.print("Error parsing arguments: {}\n\n", .{err});
                ArgParser.showHelp();
                return;
            },
        };

        if (app_config.show_help) {
            ArgParser.showHelp();
            return;
        }

        var app = TocApp.init(self.allocator, app_config);
        defer app.deinit();

        try app.run();
    }
};