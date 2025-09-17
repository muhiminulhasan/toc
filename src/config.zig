const std = @import("std");
const print = std.debug.print;

/// Configuration options for the TOC generator
pub const Config = struct {
    path: []const u8,
    append: bool = true,
    bulleted: bool = true,
    skip: u32 = 0,
    depth: u32 = 6,
    show_help: bool = false,

    const Self = @This();

    /// Initialize default configuration
    pub fn init() Self {
        return Self{
            .path = "",
            .append = true,
            .bulleted = true,
            .skip = 0,
            .depth = 6,
            .show_help = false,
        };
    }

    /// Validate configuration parameters
    pub fn validate(self: *const Self) !void {
        if (self.path.len == 0 and !self.show_help) {
            return error.PathRequired;
        }
        if (self.depth == 0 or self.depth > 6) {
            return error.InvalidDepth;
        }
    }
};

/// Command line argument parser
pub const ArgParser = struct {
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{ .allocator = allocator };
    }

    /// Parse command line arguments into Config
    pub fn parse(self: *Self, args: []const []const u8) !Config {
        _ = self; // Mark as unused since we don't need self for this operation
        var config = Config.init();

        var i: usize = 1; // Skip program name
        while (i < args.len) {
            const arg = args[i];

            if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
                config.show_help = true;
            } else if (std.mem.eql(u8, arg, "-p") or std.mem.eql(u8, arg, "--path")) {
                i += 1;
                if (i >= args.len) return error.MissingPathValue;
                config.path = args[i];
            } else if (std.mem.eql(u8, arg, "-a") or std.mem.eql(u8, arg, "--append")) {
                i += 1;
                if (i >= args.len) return error.MissingAppendValue;
                config.append = std.mem.eql(u8, args[i], "true");
            } else if (std.mem.eql(u8, arg, "-b") or std.mem.eql(u8, arg, "--bulleted")) {
                i += 1;
                if (i >= args.len) return error.MissingBulletedValue;
                config.bulleted = std.mem.eql(u8, args[i], "true");
            } else if (std.mem.eql(u8, arg, "-s") or std.mem.eql(u8, arg, "--skip")) {
                i += 1;
                if (i >= args.len) return error.MissingSkipValue;
                config.skip = try std.fmt.parseInt(u32, args[i], 10);
            } else if (std.mem.eql(u8, arg, "-d") or std.mem.eql(u8, arg, "--depth")) {
                i += 1;
                if (i >= args.len) return error.MissingDepthValue;
                config.depth = try std.fmt.parseInt(u32, args[i], 10);
            }

            i += 1;
        }

        try config.validate();
        return config;
    }

    /// Display help message
    pub fn showHelp() void {
        print(
            \\Usage: toc [options]
            \\Options:
            \\  -p, --path      <path>   Path for the markdown file.                               [REQUIRED]
            \\  -a, --append    <bool>   Append toc after <!--toc-->, or write to stdout.          [Default: true]
            \\  -b, --bulleted  <bool>   Write as bulleted, or write as numbered list.             [Default: true] 
            \\  -s, --skip      <int>    Skip the first given number of headers.                   [Default: 0]
            \\  -d, --depth     <int>    Set the number of maximum heading level to be included.   [Default: 6]
            \\  -h, --help               Show this message and exit.
            \\
        , .{});
    }
};
