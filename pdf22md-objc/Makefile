CC = clang
CFLAGS = -Wall -Wextra -O2 -fobjc-arc
FRAMEWORKS = -framework Foundation -framework PDFKit -framework CoreGraphics -framework ImageIO -framework CoreServices
TARGET = pdf22md

# Version from git tag or fallback
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "1.0.0")

# Define directories
SRC_DIR = src
BUILD_DIR = build

# Source files
CORE_SOURCES = $(wildcard $(SRC_DIR)/Core/*.m)
MODEL_SOURCES = $(wildcard $(SRC_DIR)/Models/*.m)
SERVICE_SOURCES = $(wildcard $(SRC_DIR)/Services/*.m)
CLI_SOURCES = $(SRC_DIR)/CLI/main.m

ALL_SOURCES = $(CORE_SOURCES) $(MODEL_SOURCES) $(SERVICE_SOURCES) $(CLI_SOURCES)
OBJECTS = $(patsubst $(SRC_DIR)/%.m,$(BUILD_DIR)/%.o,$(ALL_SOURCES))

# Default prefix for installation
PREFIX ?= /usr/local

all: $(BUILD_DIR) $(TARGET)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)/Core
	mkdir -p $(BUILD_DIR)/Models
	mkdir -p $(BUILD_DIR)/Services
	mkdir -p $(BUILD_DIR)/CLI

$(TARGET): $(OBJECTS)
	$(CC) $(CFLAGS) $(FRAMEWORKS) -o $(TARGET) $(OBJECTS)

$(BUILD_DIR)/Core/%.o: $(SRC_DIR)/Core/%.m | $(BUILD_DIR)
	$(CC) $(CFLAGS) -DVERSION=\"$(VERSION)\" -DPDF22MD_VERSION=\"$(VERSION)\" -I$(SRC_DIR) -c $< -o $@

$(BUILD_DIR)/Models/%.o: $(SRC_DIR)/Models/%.m | $(BUILD_DIR)
	$(CC) $(CFLAGS) -DVERSION=\"$(VERSION)\" -DPDF22MD_VERSION=\"$(VERSION)\" -I$(SRC_DIR) -c $< -o $@

$(BUILD_DIR)/Services/%.o: $(SRC_DIR)/Services/%.m | $(BUILD_DIR)
	$(CC) $(CFLAGS) -DVERSION=\"$(VERSION)\" -DPDF22MD_VERSION=\"$(VERSION)\" -I$(SRC_DIR) -c $< -o $@

$(BUILD_DIR)/CLI/%.o: $(SRC_DIR)/CLI/%.m | $(BUILD_DIR)
	$(CC) $(CFLAGS) -DVERSION=\"$(VERSION)\" -DPDF22MD_VERSION=\"$(VERSION)\" -I$(SRC_DIR) -c $< -o $@

clean:
	rm -rf $(BUILD_DIR) $(TARGET)

install: $(TARGET)
	install -d $(DESTDIR)$(PREFIX)/bin
	install -m 755 $(TARGET) $(DESTDIR)$(PREFIX)/bin/

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/$(TARGET)

test: $(TARGET)
	@echo "Running basic test..."
	./$(TARGET) -h
	./$(TARGET) -v
	@echo "Test completed successfully"

.PHONY: all clean install uninstall test