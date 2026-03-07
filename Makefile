# Makefile for sqlite-markdown extension using cmark

# Versions
CMARK_VERSION = 0.30.3
CMARK_DIR = cmark-$(CMARK_VERSION)
CMARK_TAR = $(CMARK_DIR).tar.gz
CMARK_URL = https://github.com/commonmark/cmark/archive/refs/tags/$(CMARK_VERSION).tar.gz

# Compiler settings
CC = gcc
CFLAGS = -fPIC -shared -O2 -I$(CMARK_DIR)/src -I$(CMARK_DIR)/build/src
LDFLAGS = -L$(CMARK_DIR)/build/src -lcmark

# Extension output
TARGET = markdown.so

all: $(TARGET)

# 1. Download cmark
$(CMARK_TAR):
	curl -L -o $@ $(CMARK_URL)

# 2. Extract cmark
$(CMARK_DIR): $(CMARK_TAR)
	tar -xzf $< 

# 3. Build cmark (Static library)
$(CMARK_DIR)/build/src/libcmark.a: $(CMARK_DIR)
	mkdir -p $(CMARK_DIR)/build
	cd $(CMARK_DIR)/build && cmake .. -DCMARK_TESTS=OFF -DCMARK_SHARED=OFF -DCMARK_STATIC=ON
	cd $(CMARK_DIR)/build && make

# 4. Build extension
# We link statically against libcmark.a so the .so is portable-ish
$(TARGET): extension.c $(CMARK_DIR)/build/src/libcmark.a
	$(CC) -fPIC -shared -o $@ extension.c \
		-I$(CMARK_DIR)/src \
		-I$(CMARK_DIR)/build/src \
		$(CMARK_DIR)/build/src/libcmark.a

clean:
	rm -rf $(CMARK_DIR) $(CMARK_TAR) $(TARGET)

.PHONY: all clean
