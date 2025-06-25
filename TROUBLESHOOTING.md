# Troubleshooting Guide

## Swift Build Failures

### SWBBuildService.framework Missing

**Error Message:**
```
Library not loaded: @rpath/SWBBuildService.framework/Versions/A/SWBBuildService
```

**Description:**
This error occurs when the Swift Package Manager framework is missing or corrupted in the Command Line Tools installation. This is a known issue that can happen after macOS updates or when Command Line Tools are partially installed.

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
The Objective-C implementation is fully functional and doesn't require Swift:
```bash
./build.sh --objc-only
```

### Swift Package Manager Not Working

**Symptoms:**
- `swift package` commands fail
- `swift build` exits with code 6 (Abort trap)

**Diagnosis:**
Check if Swift Package Manager is functional:
```bash
swift package --version
```

If this fails, follow the solutions for SWBBuildService.framework above.

## Build Script Issues

### Both Implementations Failing

If both Swift and Objective-C builds fail:

1. Ensure Xcode Command Line Tools are installed:
   ```bash
   xcode-select --install
   ```

2. Check tool availability:
   ```bash
   clang --version
   swift --version
   make --version
   ```

3. Reset Xcode path to default:
   ```bash
   sudo xcode-select --reset
   ```

### Permission Issues

If you encounter permission errors during installation:

1. Ensure you have sudo access
2. Check that `/usr/local/bin` exists and is writable:
   ```bash
   ls -la /usr/local/bin
   ```

## Runtime Issues

### PDF Conversion Errors

If pdf22md fails to convert specific PDFs:

1. Check PDF file permissions
2. Ensure the PDF is not encrypted or password-protected
3. Try with a different DPI setting:
   ```bash
   pdf22md -i input.pdf -o output.md -d 72
   ```

### Missing Assets Folder

If images are not being extracted:

1. Specify an assets folder explicitly:
   ```bash
   pdf22md -i input.pdf -o output.md -a ./assets
   ```

2. Ensure the parent directory has write permissions

## Getting Help

If you continue to experience issues:

1. Check the GitHub issues: https://github.com/anthropics/pdf22md/issues
2. Run the build script with verbose output and save the log:
   ```bash
   ./build.sh 2>&1 | tee build.log
   ```
3. Include the build.log when reporting issues