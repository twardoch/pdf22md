CC = clang
CFLAGS = -Wall -Wextra -O2 -fobjc-arc
FRAMEWORKS = -framework Foundation -framework PDFKit -framework CoreGraphics -framework ImageIO -framework CoreServices
TARGET = pdf22md

# Version from git tag or fallback
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")

# Define directories
SRC_DIR = src
BUILD_DIR = build

# Source and object files - look in all subdirectories, exclude benchmark
SOURCES = $(filter-out $(BENCHMARK_SRC),$(wildcard $(SRC_DIR)/*/*.m $(SRC_DIR)/*/*/*.m))
OBJECTS = $(patsubst $(SRC_DIR)/%.m,$(BUILD_DIR)/%.o,$(SOURCES))

# Default prefix for installation
PREFIX ?= /usr/local

# Additional targets
BENCHMARK = pdf22md-benchmark
BENCHMARK_SRC = src/CLI/pdf22md-benchmark.m

all: $(BUILD_DIR) $(TARGET)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(TARGET): $(OBJECTS)
	$(CC) $(CFLAGS) $(FRAMEWORKS) -o $(TARGET) $(OBJECTS)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.m | $(BUILD_DIR)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -DVERSION=\"$(VERSION)\" -Isrc -c $< -o $@

clean:
	rm -rf $(BUILD_DIR) $(TARGET) $(BENCHMARK)

install: $(TARGET)
	install -d $(DESTDIR)$(PREFIX)/bin
	install -m 755 $(TARGET) $(DESTDIR)$(PREFIX)/bin/
	install -d $(DESTDIR)$(PREFIX)/share/man/man1
	install -m 644 docs/pdf22md.1 $(DESTDIR)$(PREFIX)/share/man/man1/

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/$(TARGET)
	rm -f $(DESTDIR)$(PREFIX)/share/man/man1/pdf22md.1

# Testing
test: $(BUILD_DIR)
	@echo "🧪 Running pdf22md test suite..."
	@./run-tests.sh

test-unit: $(BUILD_DIR)
	@echo "🔬 Running unit tests..."
	@mkdir -p build/tests
	@for test in Tests/Unit/*.m; do \
		if [ -f "$$test" ]; then \
			echo "  Building $$test..."; \
			test_name=$$(basename "$$test" .m); \
			$(CC) $(CFLAGS) $(FRAMEWORKS) -Isrc \
				"$$test" src/Core/*.m src/Models/*.m src/Services/*.m \
				-o "build/tests/$$test_name" && \
			echo "  ✓ Compiled $$test_name" || echo "  ✗ Failed to compile $$test_name"; \
		fi; \
	done

test-integration: $(BUILD_DIR)
	@echo "🔬 Running integration tests..."
	@mkdir -p build/tests
	@for test in Tests/Integration/*.m; do \
		if [ -f "$$test" ]; then \
			echo "  Building $$test..."; \
			test_name=$$(basename "$$test" .m); \
			$(CC) $(CFLAGS) $(FRAMEWORKS) -Isrc \
				"$$test" src/Core/*.m src/Models/*.m src/Services/*.m \
				-o "build/tests/$$test_name" && \
			echo "  ✓ Compiled $$test_name" || echo "  ✗ Failed to compile $$test_name"; \
		fi; \
	done

test-clean:
	@echo "🧹 Cleaning test artifacts..."
	@rm -rf build/tests Tests/Resources/*.pdf

# Build benchmark tool
$(BENCHMARK): $(BUILD_DIR) $(filter-out $(BUILD_DIR)/CLI/main.o, $(OBJECTS))
	@echo "🔨 Building benchmark tool..."
	$(CC) $(CFLAGS) $(FRAMEWORKS) -o $(BENCHMARK) \
		$(filter-out $(BUILD_DIR)/CLI/main.o, $(OBJECTS))

# Benchmark and profiling
benchmark: $(BENCHMARK)
	@echo "📊 Running performance benchmarks..."
	@mkdir -p test/benchmark
	@if [ -f test/README.pdf ]; then \
		./$(BENCHMARK) --corpus test/ --json benchmark-results.json --iterations 3; \
	else \
		echo "⚠️  No test PDFs found. Add PDFs to test/ directory"; \
		echo "Creating sample benchmark..."; \
		./$(BENCHMARK) --help; \
	fi

memory-check: $(TARGET)
	@echo "🔍 Running memory leak detection..."
	@echo "Note: Install Xcode and run 'leaks' command manually for detailed analysis"
	@echo "Basic memory test with multiple conversions..."
	@for i in 1 2 3 4 5; do \
		echo "  Conversion $$i..."; \
		./$(TARGET) -i test/README.pdf -o /tmp/test_$$i.md; \
	done
	@echo "Memory test complete. Monitor Activity Monitor for memory usage."

.PHONY: all clean install uninstall test test-unit test-integration test-clean benchmark memory-check