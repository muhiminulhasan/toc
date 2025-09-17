# 📚 TOC Generator

[![Zig](https://img.shields.io/badge/Zig-0.15.0-orange.svg)](https://ziglang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://img.shields.io/badge/build-passing-brightgreen.svg)]()

> A blazingly fast and efficient Table of Contents generator for Markdown files, built with Zig.

<!--toc-->


## ✨ Features

- 🚀 **Lightning Fast**: High-performance Markdown parsing and TOC generation
- 🎯 **Flexible Output**: Support for both bulleted (`-`) and numbered (`1.`) TOC formats
- 📏 **Configurable Depth**: Control header depth levels (1-6) to include in TOC
- ⏭️ **Skip Headers**: Skip specified number of headers from the beginning
- 🔄 **In-place Updates**: Seamlessly update existing TOC sections or append new ones
- 🏗️ **Clean Architecture**: Modular design following SOLID principles
- 🛡️ **Safe & Reliable**: Memory-safe implementation with comprehensive error handling
- 📁 **Backup Support**: Automatic backup creation before file modifications

## 🚀 Quick Start

### Prerequisites

- **Zig 0.15.0** or later ([Download here](https://ziglang.org/download/))

### Installation

```bash
# Clone the repository
git clone https://github.com/muhiminulhasan/toc.git
cd toc

# Build the project
zig build

# Run tests to verify installation
zig build test
```

### Basic Usage

```bash
# Generate TOC for a markdown file
zig build run -- --path README.md

# Or use the compiled binary
./zig-out/bin/toc --path README.md
```

## 📖 Usage Guide

### Command Line Interface

```bash
Usage: toc [OPTIONS]

Options:
  -p, --path <PATH>        Path to the markdown file (required)
  -a, --append             Append TOC to the file instead of replacing
  -b, --bulleted <BOOL>    Use bulleted format (default: true)
  -s, --skip <NUMBER>      Number of headers to skip from start (default: 0)
  -d, --depth <NUMBER>     Maximum header depth to include (default: 6)
  -h, --help               Show this help message and exit
```

### 🎯 Examples

#### Basic TOC Generation

```bash
# Generate a simple bulleted TOC
zig build run -- --path docs/guide.md
```

**Input (`docs/guide.md`):**
```markdown
# Getting Started
## Installation
### Prerequisites
## Configuration
# Advanced Usage
## API Reference
```

**Output:**
```markdown
<!--toc-->
- [Getting Started](#getting-started)
  - [Installation](#installation)
    - [Prerequisites](#prerequisites)
  - [Configuration](#configuration)
- [Advanced Usage](#advanced-usage)
  - [API Reference](#api-reference)
<!--/toc-->

# Getting Started
## Installation
### Prerequisites
## Configuration
# Advanced Usage
## API Reference
```

#### Numbered TOC with Depth Limit

```bash
# Generate numbered TOC with maximum depth of 2
zig build run -- --path README.md --bulleted false --depth 2
```

**Output:**
```markdown
<!--toc-->
1. [Getting Started](#getting-started)
   1. [Installation](#installation)
   2. [Configuration](#configuration)
2. [Advanced Usage](#advanced-usage)
   1. [API Reference](#api-reference)
<!--/toc-->
```

#### Skip Headers and Append Mode

```bash
# Skip first header and append TOC to file
zig build run -- --path docs/api.md --skip 1 --append
```

**Before (`docs/api.md`):**
```markdown
# API Documentation
# Authentication
## Login
## Logout
# Endpoints
## Users
## Posts
```

**After (with `--skip 1`):**
```markdown
# API Documentation
# Authentication
## Login
## Logout
# Endpoints
## Users
## Posts

<!--toc-->
- [Authentication](#authentication)
  - [Login](#login)
  - [Logout](#logout)
- [Endpoints](#endpoints)
  - [Users](#users)
  - [Posts](#posts)
<!--/toc-->
```

#### Complex Example with All Options

```bash
# Advanced usage: numbered TOC, skip 2 headers, max depth 3, append mode
zig build run -- \
  --path complex-doc.md \
  --bulleted false \
  --skip 2 \
  --depth 3 \
  --append
```

### 🔧 TOC Markers

The generator uses HTML comments to mark TOC sections:

```markdown
<!--toc-->
<!-- TOC content will be inserted here -->
<!--/toc-->
```

- **Existing markers**: TOC content between markers will be replaced
- **No markers + append mode**: TOC will be appended to the end of the file
- **No markers + no append**: TOC will be inserted at the beginning of the file

## 🏗️ Architecture

### 📁 Project Structure

```
src/
├── main.zig                 # 🚪 CLI entry point and argument parsing
├── config.zig              # ⚙️ Configuration management
├── markdown_parser.zig     # 📝 Markdown parsing and header extraction
├── toc_generator.zig       # 🔧 TOC generation and formatting logic
├── file_handler.zig        # 📂 File I/O operations and validation
├── toc_app.zig            # 🎯 Main application orchestration
├── root.zig               # 📚 Library root and public API
└── tests/                 # 🧪 Comprehensive test suite
    ├── config_test.zig
    ├── markdown_parser_test.zig
    ├── toc_generator_test.zig
    └── file_handler_test.zig
```

## 🧪 Development

### Running Tests

```bash
# Run all unit tests
zig build test

# Run tests with verbose output
zig build test -- --verbose

# Run specific test file
zig test src/tests/markdown_parser_test.zig

# Clean build artifacts
zig build clean
```

### 📊 Test Coverage

Our test suite covers:

- ✅ **Config parsing**: All CLI argument combinations
- ✅ **Markdown parsing**: Various header formats and edge cases
- ✅ **TOC generation**: Both bulleted and numbered formats
- ✅ **File operations**: Reading, writing, and backup creation
- ✅ **Integration**: End-to-end workflow testing
- ✅ **Error handling**: Invalid inputs and file system errors

### 🔧 Building for Production

```bash
# Release build with optimizations
zig build -Doptimize=ReleaseFast

# Cross-compile for different targets
zig build -Dtarget=x86_64-linux-gnu
zig build -Dtarget=aarch64-macos-none
zig build -Dtarget=x86_64-windows-gnu
```

## 🤝 Contributing

We welcome contributions! Here's how to get started:

### 🛠️ Development Setup

1. **Fork** the repository
2. **Clone** your fork:
   ```bash
   git clone https://github.com/muhiminulhasan/toc.git
   cd toc
   ```
3. **Create** a feature branch:
   ```bash
   git checkout -b feature/amazing-feature
   ```
4. **Make** your changes following our coding standards
5. **Add** tests for new functionality
6. **Run** the test suite:
   ```bash
   zig build test
   ```
7. **Commit** your changes:
   ```bash
   git commit -m "feat: add amazing feature"
   ```
8. **Push** to your branch:
   ```bash
   git push origin feature/amazing-feature
   ```
9. **Open** a Pull Request

### 📝 Coding Standards

- Follow Zig's official style guide
- Write comprehensive tests for new features
- Document public APIs with doc comments
- Use meaningful variable and function names
- Keep functions focused and small

### 🐛 Bug Reports

Found a bug? Please open an issue with:

- **Description**: Clear description of the problem
- **Steps to reproduce**: Minimal example to reproduce the issue
- **Expected behavior**: What should happen
- **Actual behavior**: What actually happens
- **Environment**: Zig version, OS, etc.

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- 🦎 **Zig Community**: For the amazing language and standard library
- 📖 **Markdown Specification**: CommonMark for the parsing guidelines
- 🏗️ **Clean Architecture**: Robert C. Martin's principles
- 🚀 **Performance**: Inspired by Rust and Go implementations

## ☕ Support

If you find this project helpful, consider buying me a coffee! ☕

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-@muhiminulhasan-orange?style=for-the-badge&logo=buy-me-a-coffee)](https://www.buymeacoffee.com/muhiminulhasan)

Your support helps maintain and improve this project! 🚀

## 🔗 Related Projects

- [markdown-toc](https://github.com/jonschlinkert/markdown-toc) - Node.js implementation
- [doctoc](https://github.com/thlorenz/doctoc) - Another Node.js option
- [gh-md-toc](https://github.com/ekalinin/github-markdown-toc) - Bash implementation

---

<div align="center">

**[⬆ Back to Top](#-toc-generator)**

Made with ❤️ and ⚡ by the Zig community

</div>
