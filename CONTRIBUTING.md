# Contributing to pdf22md

Thank you for your interest in contributing to `pdf22md`! This document outlines how you can contribute to the project, focusing on technical details, code structure, and development guidelines.

## Project Overview

`pdf22md` is a PDF to Markdown converter with two primary implementations:

1.  **Objective-C Implementation (`pdf21md`)**: Located in the `pdf21md/` directory. This is the mature, production-ready version, optimized for macOS using Grand Central Dispatch (GCD) and native PDFKit integration.
2.  **Swift Implementation (`pdf22md`)**: Located in the `pdf22md/` directory. This is a modern implementation built with Swift Package Manager, leveraging Swift's latest concurrency features (async/await, actors).

Both implementations share the goal of high-performance, accurate PDF to Markdown conversion, including intelligent heading detection and smart image extraction.

## Codebase Structure

The project root contains shared documentation, build scripts, and the two main implementation directories:

-   `pdf21md/`: Contains the Objective-C source code, Makefile, and its specific test resources.
    -   `pdf21md/src/CLI/`: Command-line interface entry points.
    -   `pdf21md/src/Core/`: Core conversion logic, options, and error handling.
    -   `pdf21md/src/Models/`: Data models for PDF elements (text, images).
    -   `pdf21md/src/Services/`: Services like asset management and Markdown generation.
    -   `pdf21md/shared-core/`: Shared Objective-C utilities (concurrency, constants, error factory, file system).
    -   `pdf21md/shared-algorithms/`: Shared Objective-C algorithms (e.g., image format detection).
    -   `pdf21md/Tests/`: Unit and integration tests for the Objective-C version.

-   `pdf22md/`: Contains the Swift source code, `Package.swift` (Swift Package Manager manifest), and its specific test resources.
    -   `pdf22md/Sources/PDF22MD/`: Core Swift library modules.
    -   `pdf22md/Sources/PDF22MDCli/`: Swift command-line interface entry point.
    -   `pdf22md/Tests/PDF22MDTests/`: Unit tests for the Swift version.

-   `build.sh`: The main build script that compiles both implementations.
-   `test_both.sh`: Script to run tests for both implementations.
-   `docs/`: General project documentation.
-   `issues/`: Issue tracking files.

## Technical Requirements and Conventions

### General Guidelines

-   **Platform**: Development is primarily for macOS. Ensure compatibility with macOS 10.12+ for Objective-C and macOS 12.0+ for Swift.
-   **Language Standards**: Adhere to modern Objective-C (ARC, nullability annotations, lightweight generics) and Swift (Swift 5.7+, async/await, structured concurrency).
-   **Performance**: Given the nature of PDF processing, performance is critical. Contributions should be mindful of CPU and memory efficiency.
-   **Error Handling**: Use the established error handling patterns (e.g., `PDF21MDErrorFactory` for Objective-C, Swift's native `Error` protocol).
-   **Testing**: All new features and bug fixes should be accompanied by appropriate unit and/or integration tests.

### Objective-C (`pdf21md`)

-   **Prefixes**: All new classes and categories should use the `PDF21MD` prefix.
-   **Memory Management**: Use ARC. Avoid manual `retain`/`release`/`autorelease` calls.
-   **Concurrency**: Utilize `PDF21MDConcurrencyManager` for GCD-based parallel processing and queue management.
-   **File System Operations**: Use `PDF21MDFileSystemUtils` for all file and directory operations.
-   **Constants**: Refer to `PDF21MDConstants` for all configuration values and magic numbers.

### Swift (`pdf22md`)

-   **Swift Package Manager**: The project is managed with SPM. Ensure your changes integrate seamlessly.
-   **Concurrency**: Prefer Swift's `async/await` and `Actors` for concurrent operations.
-   **Error Handling**: Define custom `Error` enums where appropriate and propagate errors using `throws`.
-   **Value Types**: Prefer `struct`s over `class`es where appropriate to leverage Swift's value semantics and improve memory safety.

## Development Workflow

1.  **Fork the Repository**: Start by forking the `pdf22md` repository on GitHub.
2.  **Clone Your Fork**: `git clone https://github.com/YOUR_USERNAME/pdf22md.git`
3.  **Create a New Branch**: `git checkout -b feature/your-feature-name` or `bugfix/issue-number`.
4.  **Make Your Changes**: Implement your feature or bug fix, adhering to the technical requirements and conventions.
5.  **Write Tests**: Add or update tests to cover your changes.
6.  **Run Tests**: Ensure all tests pass for both implementations:
    ```bash
    ./test_both.sh
    ```
7.  **Build the Project**: Verify that both implementations build successfully:
    ```bash
    ./build.sh
    ```
8.  **Update Documentation**: If your changes affect functionality or usage, update `README.md`, `CHANGELOG.md`, or other relevant documentation.
9.  **Commit Your Changes**: Write clear, concise commit messages.
10. **Push to Your Fork**: `git push origin feature/your-feature-name`
11. **Open a Pull Request**: Submit a pull request to the `main` branch of the original `pdf22md` repository.

## How to Orchestrate Code Changes (Detailed)

### Identifying the Right Implementation

-   **General Features/Bug Fixes**: If a feature or bug fix applies to the core PDF conversion logic, it should ideally be implemented in *both* the Objective-C (`pdf21md`) and Swift (`pdf22md`) versions to maintain feature parity and ensure cross-language robustness. Look for existing patterns in both codebases.
-   **Performance Optimizations**: Analyze the performance bottlenecks. Some optimizations might be language-specific (e.g., GCD tuning for Objective-C, `async/await` patterns for Swift).
-   **CLI Enhancements**: Changes to command-line arguments or basic I/O will likely affect `pdf21md/src/CLI/main.m` and `pdf22md/Sources/PDF22MDCli/main.swift`.
-   **Shared Logic**: For logic that is truly independent of language-specific frameworks (e.g., complex algorithms), consider if it can be abstracted or if a direct port is more appropriate.

### Step-by-Step Implementation Example (Placeholder)

*(This section will be expanded with a detailed walkthrough of a typical code change, including how to apply it to both implementations, considerations for shared components, and testing strategies.)*

## Reporting Issues

If you find a bug or have a feature request, please open an issue on the [GitHub Issues page](https://github.com/twardoch/pdf22md/issues). Provide as much detail as possible, including steps to reproduce, expected behavior, and your environment.

## Code of Conduct

This project adheres to a [Code of Conduct](CODE_OF_CONDUCT.md - *link to be added*). By participating, you are expected to uphold this code.

## License

By contributing to `pdf22md`, you agree that your contributions will be licensed under the MIT License.
