# Makefile for pdf22md
# A blazingly fast PDF to Markdown converter for macOS

# Variables
PROJECT_NAME = pdf22md
SWIFT_DIR = pdf22md
BUILD_DIR = $(SWIFT_DIR)/.build
RELEASE_DIR = $(BUILD_DIR)/release
DEBUG_DIR = $(BUILD_DIR)/debug
BINARY_NAME = $(PROJECT_NAME)
INSTALL_PREFIX = /usr/local
INSTALL_BIN = $(INSTALL_PREFIX)/bin

# Version from git tag or fallback
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")

# Package info
BUNDLE_ID = com.twardoch.pdf22md
PKG_ID = $(BUNDLE_ID).pkg
DMG_NAME = $(PROJECT_NAME)-$(VERSION).dmg
PKG_NAME = $(PROJECT_NAME)-$(VERSION).pkg

# Directories for packaging
DIST_DIR = dist
PKG_ROOT = $(DIST_DIR)/pkgroot
PKG_SCRIPTS = $(DIST_DIR)/scripts

# Colors for output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[1;33m
BLUE = \033[0;34m
NC = \033[0m # No Color

# Default target
.PHONY: all
all: build

# Build target
.PHONY: build
build:
	@echo "$(BLUE)==>$(NC) Building $(PROJECT_NAME)..."
	@cd $(SWIFT_DIR) && swift build -c release
	@echo "$(GREEN)✓$(NC) Build complete: $(RELEASE_DIR)/$(BINARY_NAME)"

# Debug build
.PHONY: debug
debug:
	@echo "$(BLUE)==>$(NC) Building $(PROJECT_NAME) (debug)..."
	@cd $(SWIFT_DIR) && swift build
	@echo "$(GREEN)✓$(NC) Debug build complete: $(DEBUG_DIR)/$(BINARY_NAME)"

# Install target
.PHONY: install
install: build
	@echo "$(BLUE)==>$(NC) Installing $(PROJECT_NAME) to $(INSTALL_BIN)..."
	@sudo mkdir -p $(INSTALL_BIN)
	@sudo cp $(RELEASE_DIR)/$(BINARY_NAME) $(INSTALL_BIN)/$(BINARY_NAME)
	@sudo chmod 755 $(INSTALL_BIN)/$(BINARY_NAME)
	@echo "$(GREEN)✓$(NC) Installed $(PROJECT_NAME) to $(INSTALL_BIN)/$(BINARY_NAME)"

# Uninstall target
.PHONY: uninstall
uninstall:
	@echo "$(BLUE)==>$(NC) Uninstalling $(PROJECT_NAME)..."
	@sudo rm -f $(INSTALL_BIN)/$(BINARY_NAME)
	@echo "$(GREEN)✓$(NC) Uninstalled $(PROJECT_NAME)"

# Clean target
.PHONY: clean
clean:
	@echo "$(BLUE)==>$(NC) Cleaning build artifacts..."
	@cd $(SWIFT_DIR) && swift package clean
	@rm -rf $(BUILD_DIR)
	@rm -rf $(DIST_DIR)
	@echo "$(GREEN)✓$(NC) Clean complete"

# Test target
.PHONY: test
test: build
	@echo "$(BLUE)==>$(NC) Running tests..."
	@cd $(SWIFT_DIR) && swift test
	@echo "$(GREEN)✓$(NC) Tests complete"

# Create distribution package
.PHONY: dist
dist: build create-pkg create-dmg
	@echo "$(GREEN)✓$(NC) Distribution package created: $(DIST_DIR)/$(DMG_NAME)"

# Create pkg installer
.PHONY: create-pkg
create-pkg: build
	@echo "$(BLUE)==>$(NC) Creating installer package..."
	@mkdir -p $(PKG_ROOT)/usr/local/bin
	@mkdir -p $(PKG_SCRIPTS)
	@cp $(RELEASE_DIR)/$(BINARY_NAME) $(PKG_ROOT)/usr/local/bin/
	@chmod 755 $(PKG_ROOT)/usr/local/bin/$(BINARY_NAME)
	
	# Create postinstall script
	@echo '#!/bin/bash' > $(PKG_SCRIPTS)/postinstall
	@echo 'echo "$(PROJECT_NAME) has been installed to /usr/local/bin"' >> $(PKG_SCRIPTS)/postinstall
	@echo 'echo "You can now use it by running: $(BINARY_NAME)"' >> $(PKG_SCRIPTS)/postinstall
	@chmod 755 $(PKG_SCRIPTS)/postinstall
	
	# Build the package
	@pkgbuild --root $(PKG_ROOT) \
		--identifier $(PKG_ID) \
		--version $(VERSION) \
		--scripts $(PKG_SCRIPTS) \
		--install-location / \
		$(DIST_DIR)/$(PKG_NAME)
	
	@echo "$(GREEN)✓$(NC) Package created: $(DIST_DIR)/$(PKG_NAME)"

# Create DMG
.PHONY: create-dmg
create-dmg: create-pkg
	@echo "$(BLUE)==>$(NC) Creating DMG..."
	@mkdir -p $(DIST_DIR)/dmg
	@cp $(DIST_DIR)/$(PKG_NAME) $(DIST_DIR)/dmg/
	@cp README.md $(DIST_DIR)/dmg/
	@cp LICENSE $(DIST_DIR)/dmg/
	
	# Create a simple install instructions file
	@echo "# Installation Instructions" > $(DIST_DIR)/dmg/INSTALL.txt
	@echo "" >> $(DIST_DIR)/dmg/INSTALL.txt
	@echo "1. Double-click $(PKG_NAME) to install $(PROJECT_NAME)" >> $(DIST_DIR)/dmg/INSTALL.txt
	@echo "2. The tool will be installed to /usr/local/bin/$(BINARY_NAME)" >> $(DIST_DIR)/dmg/INSTALL.txt
	@echo "3. You can then use it from Terminal by typing: $(BINARY_NAME)" >> $(DIST_DIR)/dmg/INSTALL.txt
	
	# Create DMG
	@hdiutil create -volname "$(PROJECT_NAME) $(VERSION)" \
		-srcfolder $(DIST_DIR)/dmg \
		-ov -format UDZO \
		$(DIST_DIR)/$(DMG_NAME)
	
	# Clean up
	@rm -rf $(DIST_DIR)/dmg
	@echo "$(GREEN)✓$(NC) DMG created: $(DIST_DIR)/$(DMG_NAME)"

# Show version
.PHONY: version
version:
	@echo "$(VERSION)"

# Help target
.PHONY: help
help:
	@echo "$(PROJECT_NAME) Makefile"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build       - Build the release version (default)"
	@echo "  debug       - Build the debug version"
	@echo "  install     - Install to $(INSTALL_BIN)"
	@echo "  uninstall   - Remove from $(INSTALL_BIN)"
	@echo "  clean       - Clean build artifacts"
	@echo "  test        - Run tests"
	@echo "  dist        - Create distribution package (.dmg with .pkg)"
	@echo "  version     - Show current version"
	@echo "  help        - Show this help message"