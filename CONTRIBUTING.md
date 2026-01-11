# Contributing to pdf22md

This document explains how to contribute to `pdf22md`. It covers the code structure, technical requirements, and development workflow.

## Project Overview

`pdf22md` converts PDFs to Markdown using Swift. It uses modern concurrency features (async/await, actors) and Swift Package Manager. Key features include accurate text conversion, heading detection, and image extraction.

## Codebase Structure

The project root contains documentation, build scripts, and the main Swift implementation:

- `pdf22md/`: Swift source code, `Package.swift`, and test resources
  - `Sources/PDF22MD/`: Core library modules
  - `Sources/PDF22MDCli/`: Command-line interface
  - `Tests/PDF22MDTests/`: Unit tests
- `Makefile`: Build automation (build, install, dist)
- `build.sh`: Alternative build script
- `test.sh`: Test runner
- `docs/`: Documentation files
- `issues/`: Issue tracking

## Technical Requirements

### Development Environment

- **Platform**: macOS 12.0+
- **Language**: Swift 5.7+ with async/await and structured concurrency

### Performance and Error Handling

- **Performance**: PDF processing is CPU-intensive. Optimize for efficiency.
- **Error Handling**: Use Swift's `Error` protocol and custom error enums
- **Testing**: Add unit or integration tests for new features and bug fixes

### Swift Conventions

- **Package Manager**: Use Swift Package Manager for dependencies
- **Concurrency**: Use `async/await` and `Actors` for concurrent operations
- **Types**: Prefer `struct` over `class` for value semantics and memory safety
- **Style**: Follow Swift API Design Guidelines. Use SwiftFormat for formatting

## Development Workflow

1. Fork the repository on GitHub
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/pdf22md.git`
3. Create a branch: `git checkout -b feature/your-feature-name` or `bugfix/issue-number`
4. Implement changes following technical requirements
5. Add or update tests
6. Run tests: `./test.sh`
7. Build project: `make build`
8. Update documentation if needed (`README.md`, `CHANGELOG.md`)
9. Commit changes with clear messages
10. Push to your fork: `git push origin feature/your-feature-name`
11. Open pull request to `main` branch

## Where to Contribute

### Core Areas

- **PDF Processing**: Text extraction, heading detection, image handling in `Sources/PDF22MD/`
- **Performance**: Optimize async/await patterns and concurrent processing
- **CLI**: Command-line arguments and I/O in `Sources/PDF22MDCli/main.swift`
- **Testing**: Add coverage for edge cases

### Guidelines

1. Use modern Swift features appropriately
2. Maintain backward compatibility
3. Comment complex logic clearly
4. Test with diverse PDF samples

## Reporting Issues

Open issues on [GitHub](https://github.com/twardoch/pdf22md/issues) with:
- Steps to reproduce
- Expected behavior
- Environment details

## Code of Conduct

Follow the [Code of Conduct](CODE_OF_CONDUCT.md). 

## License

Contributions are licensed under the MIT License.