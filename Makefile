CC = clang
CFLAGS = -Wall -Wextra -O2 -fobjc-arc
FRAMEWORKS = -framework Foundation -framework PDFKit -framework CoreGraphics -framework ImageIO -framework CoreServices
TARGET = pdf22md

# Version from git tag or fallback
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")

# Define directories
SRC_DIR = src
BUILD_DIR = build

# Source and object files
SOURCES = $(wildcard $(SRC_DIR)/*.m)
OBJECTS = $(patsubst $(SRC_DIR)/%.m,$(BUILD_DIR)/%.o,$(SOURCES))

# Default prefix for installation
PREFIX ?= /usr/local

all: $(BUILD_DIR) $(TARGET)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(TARGET): $(OBJECTS)
	$(CC) $(CFLAGS) $(FRAMEWORKS) -o $(TARGET) $(OBJECTS)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.m | $(BUILD_DIR)
	$(CC) $(CFLAGS) -DVERSION=\"$(VERSION)\" -c $< -o $@

clean:
	rm -rf $(BUILD_DIR) $(TARGET)

install: $(TARGET)
	install -d $(DESTDIR)$(PREFIX)/bin
	install -m 755 $(TARGET) $(DESTDIR)$(PREFIX)/bin/

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/$(TARGET)

# Swift targets
swift-build:
	cd swift && swift build -c release

swift-clean:
	cd swift && swift package clean

swift-test:
	cd swift && swift test

# Benchmark targets
benchmarks: all swift-build
	@echo "Both implementations built. Run ./run-benchmarks.sh to execute benchmarks"

# Build everything
all-implementations: all swift-build

.PHONY: all clean install uninstall swift-build swift-clean swift-test benchmarks all-implementations