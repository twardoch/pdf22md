# pdf22md-objc Makefile
# this_file: pdf22md-objc/Makefile

CC = clang
CFLAGS = -Wall -Wextra -std=c11 -O2
OBJCFLAGS = -fobjc-arc -framework Foundation -framework CoreGraphics -framework PDFKit -framework ImageIO -framework AppKit
TARGET = pdf22md
SRCDIR = src
SOURCES = $(SRCDIR)/CLI/main.m $(wildcard $(SRCDIR)/Core/*.m) $(wildcard $(SRCDIR)/Models/*.m) $(wildcard $(SRCDIR)/Services/*.m) $(wildcard shared-core/*.m) $(wildcard shared-algorithms/*.m)
HEADERS = $(wildcard $(SRCDIR)/**/*.h) $(wildcard shared-core/*.h) $(wildcard shared-algorithms/*.h)
OBJECTS = $(SOURCES:.m=.o)

# Default target
all: $(TARGET)

# Build the main executable
$(TARGET): $(OBJECTS)
	$(CC) $(OBJCFLAGS) -o $@ $^

# Compile Objective-C source files
%.o: %.m $(HEADERS)
	$(CC) $(CFLAGS) $(OBJCFLAGS) -c $< -o $@

# Install target
install: $(TARGET)
	cp $(TARGET) /usr/local/bin/

# Clean build artifacts
clean:
	rm -f $(OBJECTS) $(TARGET)

# Run tests
test: $(TARGET)
	@echo "Running tests..."
	# Add test commands here

# Build benchmark
benchmark: pdf22md-benchmark

pdf22md-benchmark: $(SRCDIR)/CLI/pdf22md-benchmark.m $(filter-out $(SRCDIR)/CLI/main.o,$(OBJECTS))
	$(CC) $(OBJCFLAGS) -o $@ $^

# Phony targets
.PHONY: all clean install test benchmark

# Debug build
debug: CFLAGS += -g -DDEBUG
debug: $(TARGET)

# Print variables for debugging
print-%:
	@echo $* = $($*) 