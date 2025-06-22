CC = clang
CFLAGS = -Wall -Wextra -O2 -fobjc-arc
FRAMEWORKS = -framework Foundation -framework PDFKit -framework CoreGraphics -framework ImageIO -framework CoreServices
TARGET = pdf22md
SOURCES = main.m PDFMarkdownConverter.m PDFPageProcessor.m ContentElement.m AssetExtractor.m
OBJECTS = $(SOURCES:.m=.o)

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) $(CFLAGS) $(FRAMEWORKS) -o $(TARGET) $(OBJECTS)

%.o: %.m
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJECTS) $(TARGET)

install: $(TARGET)
	install -m 755 $(TARGET) /usr/local/bin/

uninstall:
	rm -f /usr/local/bin/$(TARGET)

.PHONY: all clean install uninstall