const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        // .default_target = .{
        //     .cpu_arch = .x86_64,
        //     .os_tag = .windows,
        // },
    });
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSmall,
    });

    // Main executable
    const exe = b.addExecutable(.{
        .name = "toc",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(exe);

    // Run command
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the TOC generator");
    run_step.dependOn(&run_cmd.step);

    // Test configuration
    const test_step = b.step("test", "Run unit tests");

    // Individual test files
    const test_files = [_][]const u8{
        "src/tests/config_test.zig",
        "src/tests/markdown_parser_test.zig",
        "src/tests/toc_generator_test.zig",
        "src/tests/file_handler_test.zig",
    };

    for (test_files) |test_file| {
        const unit_tests = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path(test_file),
                .target = target,
                .optimize = optimize,
            }),
        });

        const run_unit_tests = b.addRunArtifact(unit_tests);
        test_step.dependOn(&run_unit_tests.step);
    }

    // Integration test step
    const integration_test_step = b.step("test-integration", "Run integration tests");

    // Create a test markdown file and run the tool on it
    const create_test_file = b.addWriteFiles();
    _ = create_test_file.add("test.md",
        \\# Test Document
        \\
        \\<!--toc-->
        \\<!--/toc-->
        \\
        \\## Section 1
        \\
        \\Content for section 1.
        \\
        \\### Subsection 1.1
        \\
        \\More content.
        \\
        \\## Section 2
        \\
        \\Content for section 2.
    );

    const integration_run = b.addRunArtifact(exe);
    integration_run.addArg("-p");
    integration_run.addArg("test.md");
    integration_run.step.dependOn(&create_test_file.step);

    integration_test_step.dependOn(&integration_run.step);

    // Clean step
    const clean_step = b.step("clean", "Clean build artifacts");
    const clean_cmd = b.addSystemCommand(&[_][]const u8{ "rm", "-rf", "zig-out", "zig-cache" });
    clean_step.dependOn(&clean_cmd.step);

    // Install step with better description
    const install_step = b.getInstallStep();
    install_step.dependOn(&exe.step);

    // Help step
    const help_step = b.step("help", "Show available build commands");
    const help_cmd = b.addSystemCommand(&[_][]const u8{
        "echo",
        \\Available commands:
        \\  zig build                 - Build the TOC generator
        \\  zig build run             - Build and run the TOC generator
        \\  zig build test            - Run all unit tests
        \\  zig build test-integration - Run integration tests
        \\  zig build clean           - Clean build artifacts
        \\  zig build help            - Show this help message
        \\
        \\Usage examples:
        \\  zig build run -- -p README.md
        \\  zig build run -- --path docs/guide.md --bulleted false
    });
    help_step.dependOn(&help_cmd.step);
}
