
BASESOURCES += storage.cpp CharacterSet.cpp
BASESOURCES += external/libsquash/src/cache.c external/libsquash/src/decompress.c external/libsquash/src/dir.c external/libsquash/src/dirent.c external/libsquash/src/fd.c external/libsquash/src/file.c external/libsquash/src/fs.c external/libsquash/src/hash.c external/libsquash/src/mutex.c external/libsquash/src/nonstd-makedev.c external/libsquash/src/nonstd-stat.c external/libsquash/src/private.c external/libsquash/src/readlink.c external/libsquash/src/scandir.c external/libsquash/src/stack.c external/libsquash/src/stat.c external/libsquash/src/table.c external/libsquash/src/traverse.c external/libsquash/src/util.c
SOURCES += $(BASESOURCES)

INCFLAGS += -Iexternal/lz4/lib
INCFLAGS += -Iexternal/zstd/lib
INCFLAGS += -Iexternal/libsquash/include
LDLIBS += -luuid

PROJECT_BASENAME = krsquashfs

include external/ncbind/Rules.lib.make

DEPENDENCY_BUILD_DIRECTORY := build-$(TARGET_ARCH)
DEPENDENCY_BUILD_DIRECTORY_ZLIB := $(DEPENDENCY_BUILD_DIRECTORY)/zlib
DEPENDENCY_BUILD_DIRECTORY_XZ := $(DEPENDENCY_BUILD_DIRECTORY)/xz
DEPENDENCY_BUILD_DIRECTORY_LZO := $(DEPENDENCY_BUILD_DIRECTORY)/lzo
DEPENDENCY_BUILD_DIRECTORY_LZ4 := $(DEPENDENCY_BUILD_DIRECTORY)/lz4
DEPENDENCY_BUILD_DIRECTORY_ZSTD := $(DEPENDENCY_BUILD_DIRECTORY)/zstd

ZLIB_PATH := $(realpath external/zlib)
XZ_PATH := $(realpath external/xz)
LZO_PATH := $(realpath external/lzo)
LZ4_PATH := $(realpath external/lz4)
ZSTD_PATH := $(realpath external/zstd)

DEPENDENCY_OUTPUT_DIRECTORY := $(shell realpath build-libraries)-$(TARGET_ARCH)

EXTLIBS += $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libz.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/liblzma.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/liblzo2.a external/lz4/lib/liblz4.a external/zstd/lib/libzstd.a
SOURCES += $(EXTLIBS)
OBJECTS += $(EXTLIBS)
LDLIBS += $(EXTLIBS)

INCFLAGS += -I$(DEPENDENCY_OUTPUT_DIRECTORY)/include

$(BASESOURCES): $(EXTLIBS)

clean::
	rm -rf $(DEPENDENCY_BUILD_DIRECTORY) $(DEPENDENCY_OUTPUT_DIRECTORY)
	$(MAKE) -C external/lz4 clean
	$(MAKE) -C external/zstd clean

$(DEPENDENCY_OUTPUT_DIRECTORY):
	mkdir -p $(DEPENDENCY_OUTPUT_DIRECTORY)

$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libz.a: $(DEPENDENCY_OUTPUT_DIRECTORY)
	mkdir -p $(DEPENDENCY_BUILD_DIRECTORY_ZLIB) && \
	cd $(DEPENDENCY_BUILD_DIRECTORY_ZLIB) && \
	PKG_CONFIG_PATH=$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/pkgconfig \
	CFLAGS="-O2" \
	CROSS_PREFIX="$(TOOL_TRIPLET_PREFIX)" \
	$(ZLIB_PATH)/configure \
		--prefix="$(DEPENDENCY_OUTPUT_DIRECTORY)" \
		--static \
	&& \
	$(MAKE) && \
	$(MAKE) install

external/xz/configure:
	cd external/xz && \
	git reset --hard && \
	NOCONFIGURE=1 ./autogen.sh

$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/liblzma.a: $(DEPENDENCY_OUTPUT_DIRECTORY) external/xz/configure
	mkdir -p $(DEPENDENCY_BUILD_DIRECTORY_XZ) && \
	cd $(DEPENDENCY_BUILD_DIRECTORY_XZ) && \
	PKG_CONFIG_PATH=$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/pkgconfig \
	$(XZ_PATH)/configure \
		CFLAGS="-O2" \
		--prefix="$(DEPENDENCY_OUTPUT_DIRECTORY)" \
		--enable-threads=no \
		--disable-xz \
		--disable-xzdec \
		--disable-lzmadec \
		--disable-lzmainfo \
		--disable-lzma-links \
		--disable-scripts \
		--disable-doc \
		--enable-shared=no \
		--enable-static=yes \
		--host=$(patsubst %-,%,$(TOOL_TRIPLET_PREFIX)) \
	&& \
	$(MAKE) && \
	$(MAKE) install

$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/liblzo2.a: $(DEPENDENCY_OUTPUT_DIRECTORY)
	mkdir -p $(DEPENDENCY_BUILD_DIRECTORY_LZO) && \
	cd $(DEPENDENCY_BUILD_DIRECTORY_LZO) && \
	PKG_CONFIG_PATH=$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/pkgconfig \
	$(LZO_PATH)/configure \
		CFLAGS="-O2" \
		--prefix="$(DEPENDENCY_OUTPUT_DIRECTORY)" \
		--enable-shared=no \
		--enable-static=yes \
		--host=$(patsubst %-,%,$(TOOL_TRIPLET_PREFIX)) \
	&& \
	$(MAKE) && \
	$(MAKE) install

external/lz4/lib/liblz4.a:
	cd external/lz4 && \
	$(MAKE) CC=$(CC) AR=$(AR) LD=$(LD) WINDRES=$(WINDRES) TARGET_OS=Windows CFLAGS="-O2" TARGET_ARCH= lib

external/zstd/lib/libzstd.a:
	cd external/zstd/lib && \
	$(MAKE) CC=$(CC) AR=$(AR) LD=$(LD) WINDRES=$(WINDRES) TARGET_OS=Windows TARGET_SYSTEM=Windows_NT CFLAGS="-O2" TARGET_ARCH= libzstd.a
