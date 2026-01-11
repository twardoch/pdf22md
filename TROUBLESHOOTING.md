# Troubleshooting Guide

## Swift Build Failures

### SWBBuildService.framework Missing

**Error Message:**
```
Library not loaded: @rpath/SWBBuildService.framework/Versions/A/SWBBuildService
```

**Description:**
The Swift Package Manager framework is missing or corrupted in your Command Line Tools installation. This typically happens after macOS updates or incomplete tool installations.

**Solutions:**

#### Option 1: Switch to Xcode's Swift toolchain (if Xcode is installed)
```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

#### Option 2: Reinstall Command Line Tools
```bash
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install
```

#### Option 3: Use the Objective-C implementation
The Objective-C version works fine and doesn't need Swift:
```bash
./build.sh --objc-only
```

### Swift Package Manager Not Working

**Symptoms:**
- `swift package` commands fail
- `swift build` exits with code 6 (Abort trap)

**Diagnosis:**
Test Swift Package Manager:
```bash
swift package --version
```

If this fails, use the solutions above for SWBBuildService.framework.

## Build Script Issues

### Both Implementations Failing

When Swift and Objective-C builds both fail:

1. Install Xcode Command Line Tools:
   ```bash
   xcode-select --install
   ```

2. Verify tools are available:
   ```bash
   clang --version
   swift --version
   make --version
   ```

3. Reset Xcode path:
   ```bash
   sudo xcode-select --reset
   ```

### Permission Issues

For permission errors during installation:

1. Confirm sudo access
2. Check `/usr/local/bin` permissions:
   ```bash
   ls -la /usr/local/bin
   ```

## Runtime Issues

### PDF Conversion Errors

When pdf22md can't convert specific PDFs:

1. Check PDF file permissions
2. Verify the PDF isn't encrypted
3. Try a different DPI setting:
   ```bash
   pdf22md -i input.pdf -o output.md -d 72
   ```

### Missing Assets Folder

When images aren't extracted:

1. Specify an assets folder:
   ```bash
   pdf22md -i input.pdf -o output.md -a ./assets
   ```

2. Ensure the parent directory is writable

## Getting Help

Persistent issues:

1. Check GitHub issues: https://github.com/anthropics/pdf22md/issues
2. Run build with verbose output:
   ```bash
   ./build.sh 2>&1 | tee build.log
   ```
3. Include build.log when reporting problems