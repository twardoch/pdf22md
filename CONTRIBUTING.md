# Contributing to pdf22md

Thank you for your interest in contributing to `pdf22md`! This document outlines how you can contribute to the project, focusing on technical details, code structure, and development guidelines.

## Project Overview

`pdf22md` is a high-performance PDF to Markdown converter built with Swift, leveraging Swift's latest concurrency features (async/await, actors) and Swift Package Manager. The project focuses on accurate PDF conversion with intelligent heading detection and smart image extraction.

## Codebase Structure

The project root contains shared documentation, build scripts, and the main Swift implementation:

-   `pdf22md/`: Contains the Swift source code, `Package.swift` (Swift Package Manager manifest), and test resources.
    -   `pdf22md/Sources/PDF22MD/`: Core Swift library modules.
    -   `pdf22md/Sources/PDF22MDCli/`: Swift command-line interface entry point.
    -   `pdf22md/Tests/PDF22MDTests/`: Unit tests.

-   `Makefile`: Main build automation (build, install, dist targets).
-   `build.sh`: Alternative build script.
-   `test.sh`: Script to run tests.
-   `docs/`: General project documentation.
-   `issues/`: Issue tracking files.

## Technical Requirements and Conventions

### General Guidelines

-   **Platform**: Development is for macOS 12.0+.
-   **Language Standards**: Use Swift 5.7+ with async/await and structured concurrency.
-   **Performance**: Given the nature of PDF processing, performance is critical. Contributions should be mindful of CPU and memory efficiency.
-   **Error Handling**: Use Swift's native `Error` protocol and custom error enums.
-   **Testing**: All new features and bug fixes should be accompanied by appropriate unit and/or integration tests.

### Swift Development

-   **Swift Package Manager**: The project is managed with SPM. Ensure your changes integrate seamlessly.
-   **Concurrency**: Use Swift's `async/await` and `Actors` for concurrent operations.
-   **Error Handling**: Define custom `Error` enums where appropriate and propagate errors using `throws`.
-   **Value Types**: Prefer `struct`s over `class`es where appropriate to leverage Swift's value semantics and improve memory safety.
-   **Code Style**: Follow Swift's API Design Guidelines and use SwiftFormat for consistent formatting.

## Development Workflow

1.  **Fork the Repository**: Start by forking the `pdf22md` repository on GitHub.
2.  **Clone Your Fork**: `git clone https://github.com/YOUR_USERNAME/pdf22md.git`
3.  **Create a New Branch**: `git checkout -b feature/your-feature-name` or `bugfix/issue-number`.
4.  **Make Your Changes**: Implement your feature or bug fix, adhering to the technical requirements and conventions.
5.  **Write Tests**: Add or update tests to cover your changes.
6.  **Run Tests**: Ensure all tests pass:
    ```bash
    ./test.sh
    ```
7.  **Build the Project**: Verify the build succeeds:
    ```bash
    make build
    ```
8.  **Update Documentation**: If your changes affect functionality or usage, update `README.md`, `CHANGELOG.md`, or other relevant documentation.
9.  **Commit Your Changes**: Write clear, concise commit messages.
10. **Push to Your Fork**: `git push origin feature/your-feature-name`
11. **Open a Pull Request**: Submit a pull request to the `main` branch of the original `pdf22md` repository.

## How to Orchestrate Code Changes

### Key Areas for Contribution

-   **Core PDF Processing**: Enhancements to text extraction, heading detection, or image handling in `pdf22md/Sources/PDF22MD/`.
-   **Performance Optimizations**: Improvements to async/await patterns and concurrent processing.
-   **CLI Enhancements**: Changes to command-line arguments or I/O handling in `pdf22md/Sources/PDF22MDCli/main.swift`.
-   **Testing**: Expanding test coverage for edge cases in PDF processing.

### Implementation Guidelines

1. **Follow Swift Best Practices**: Use Swift's modern features effectively.
2. **Maintain Backward Compatibility**: Ensure changes don't break existing functionality.
3. **Document Complex Logic**: Add clear comments for non-obvious implementations.
4. **Consider Edge Cases**: PDFs can vary widely; test with diverse samples.

## Reporting Issues

If you find a bug or have a feature request, please open an issue on the [GitHub Issues page](https://github.com/twardoch/pdf22md/issues). Provide as much detail as possible, including steps to reproduce, expected behavior, and your environment.

## Code of Conduct

This project adheres to a [Code of Conduct](CODE_OF_CONDUCT.md - *link to be added*). By participating, you are expected to uphold this code.

## License

By contributing to `pdf22md`, you agree that your contributions will be licensed under the MIT License.
