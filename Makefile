
BASESOURCES += storage.cpp CharacterSet.cpp
BASESOURCES += external/libsquash/src/cache.c external/libsquash/src/decompress.c external/libsquash/src/dir.c external/libsquash/src/dirent.c external/libsquash/src/fd.c external/libsquash/src/file.c external/libsquash/src/fs.c external/libsquash/src/hash.c external/libsquash/src/mutex.c external/libsquash/src/nonstd-makedev.c external/libsquash/src/nonstd-stat.c external/libsquash/src/private.c external/libsquash/src/readlink.c external/libsquash/src/scandir.c external/libsquash/src/stack.c external/libsquash/src/stat.c external/libsquash/src/table.c external/libsquash/src/traverse.c external/libsquash/src/util.c
SOURCES += $(BASESOURCES)

INCFLAGS += -Iexternal/libsquash/include
LDLIBS += -luuid

PROJECT_BASENAME = krsquashfs

include external/ncbind/Rules.lib.make

DEPENDENCY_SOURCE_DIRECTORY := $(abspath build-source)
DEPENDENCY_SOURCE_DIRECTORY_ZLIB := $(DEPENDENCY_SOURCE_DIRECTORY)/zlib
DEPENDENCY_SOURCE_DIRECTORY_XZ := $(DEPENDENCY_SOURCE_DIRECTORY)/xz
DEPENDENCY_SOURCE_DIRECTORY_LZO := $(DEPENDENCY_SOURCE_DIRECTORY)/lzo
# Since the LZ4 and Zstandard build systems don't support out of tree builds, we'll just use separate paths per arch instead
DEPENDENCY_SOURCE_DIRECTORY_LZ4 := $(DEPENDENCY_SOURCE_DIRECTORY)/lz4-$(TARGET_ARCH)
DEPENDENCY_SOURCE_DIRECTORY_ZSTD := $(DEPENDENCY_SOURCE_DIRECTORY)/zstd-$(TARGET_ARCH)

DEPENDENCY_SOURCE_FILE_ZLIB := $(DEPENDENCY_SOURCE_DIRECTORY)/zlib.tar.xz
DEPENDENCY_SOURCE_FILE_XZ := $(DEPENDENCY_SOURCE_DIRECTORY)/xz.tar.xz
DEPENDENCY_SOURCE_FILE_LZO := $(DEPENDENCY_SOURCE_DIRECTORY)/lzo.tar.gz
DEPENDENCY_SOURCE_FILE_LZ4 := $(DEPENDENCY_SOURCE_DIRECTORY)/lz4.tar.gz
DEPENDENCY_SOURCE_FILE_ZSTD := $(DEPENDENCY_SOURCE_DIRECTORY)/zstd.tar.gz

DEPENDENCY_SOURCE_URL_ZLIB := https://github.com/madler/zlib/archive/refs/tags/v1.2.12.tar.gz
DEPENDENCY_SOURCE_URL_XZ := https://tukaani.org/xz/xz-5.2.6.tar.xz
DEPENDENCY_SOURCE_URL_LZO := https://www.oberhumer.com/opensource/lzo/download/lzo-2.10.tar.gz
DEPENDENCY_SOURCE_URL_LZ4 := https://github.com/lz4/lz4/archive/refs/tags/v1.9.4.tar.gz
DEPENDENCY_SOURCE_URL_ZSTD := https://github.com/facebook/zstd/releases/download/v1.5.2/zstd-1.5.2.tar.gz

$(DEPENDENCY_SOURCE_DIRECTORY):
	mkdir -p $@

$(DEPENDENCY_SOURCE_FILE_ZLIB): | $(DEPENDENCY_SOURCE_DIRECTORY)
	curl --location --output $@ $(DEPENDENCY_SOURCE_URL_ZLIB)

$(DEPENDENCY_SOURCE_FILE_XZ): | $(DEPENDENCY_SOURCE_DIRECTORY)
	curl --location --output $@ $(DEPENDENCY_SOURCE_URL_XZ)

$(DEPENDENCY_SOURCE_FILE_LZO): | $(DEPENDENCY_SOURCE_DIRECTORY)
	curl --location --output $@ $(DEPENDENCY_SOURCE_URL_LZO)

$(DEPENDENCY_SOURCE_FILE_LZ4): | $(DEPENDENCY_SOURCE_DIRECTORY)
	curl --location --output $@ $(DEPENDENCY_SOURCE_URL_LZ4)

$(DEPENDENCY_SOURCE_FILE_ZSTD): | $(DEPENDENCY_SOURCE_DIRECTORY)
	curl --location --output $@ $(DEPENDENCY_SOURCE_URL_ZSTD)

$(DEPENDENCY_SOURCE_DIRECTORY_ZLIB): $(DEPENDENCY_SOURCE_FILE_ZLIB)
	mkdir -p $@
	tar -x -f $< -C $@ --strip-components 1

$(DEPENDENCY_SOURCE_DIRECTORY_XZ): $(DEPENDENCY_SOURCE_FILE_XZ)
	mkdir -p $@
	tar -x -f $< -C $@ --strip-components 1

$(DEPENDENCY_SOURCE_DIRECTORY_LZO): $(DEPENDENCY_SOURCE_FILE_LZO)
	mkdir -p $@
	tar -x -f $< -C $@ --strip-components 1

$(DEPENDENCY_SOURCE_DIRECTORY_LZ4): $(DEPENDENCY_SOURCE_FILE_LZ4)
	mkdir -p $@
	tar -x -f $< -C $@ --strip-components 1

$(DEPENDENCY_SOURCE_DIRECTORY_ZSTD): $(DEPENDENCY_SOURCE_FILE_ZSTD)
	mkdir -p $@
	tar -x -f $< -C $@ --strip-components 1

DEPENDENCY_BUILD_DIRECTORY := $(abspath build-$(TARGET_ARCH))
DEPENDENCY_BUILD_DIRECTORY_ZLIB := $(DEPENDENCY_BUILD_DIRECTORY)/zlib
DEPENDENCY_BUILD_DIRECTORY_XZ := $(DEPENDENCY_BUILD_DIRECTORY)/xz
DEPENDENCY_BUILD_DIRECTORY_LZO := $(DEPENDENCY_BUILD_DIRECTORY)/lzo
DEPENDENCY_BUILD_DIRECTORY_LZ4 := $(DEPENDENCY_BUILD_DIRECTORY)/lz4
DEPENDENCY_BUILD_DIRECTORY_ZSTD := $(DEPENDENCY_BUILD_DIRECTORY)/zstd

DEPENDENCY_OUTPUT_DIRECTORY := $(abspath build-libraries)-$(TARGET_ARCH)

EXTLIBS += $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libz.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/liblzma.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/liblzo2.a $(DEPENDENCY_SOURCE_DIRECTORY_LZ4)/lib/liblz4.a $(DEPENDENCY_SOURCE_DIRECTORY_ZSTD)/lib/libzstd.a
SOURCES += $(EXTLIBS)
OBJECTS += $(EXTLIBS)
LDLIBS += $(EXTLIBS)

INCFLAGS += -I$(DEPENDENCY_SOURCE_DIRECTORY_LZ4)/lib
INCFLAGS += -I$(DEPENDENCY_SOURCE_DIRECTORY_ZSTD)/lib
INCFLAGS += -I$(DEPENDENCY_OUTPUT_DIRECTORY)/include

$(BASESOURCES): $(EXTLIBS)

clean::
	rm -rf $(DEPENDENCY_SOURCE_DIRECTORY) $(DEPENDENCY_BUILD_DIRECTORY) $(DEPENDENCY_OUTPUT_DIRECTORY)

$(DEPENDENCY_OUTPUT_DIRECTORY):
	mkdir -p $(DEPENDENCY_OUTPUT_DIRECTORY)

$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libz.a: | $(DEPENDENCY_SOURCE_DIRECTORY_ZLIB) $(DEPENDENCY_OUTPUT_DIRECTORY)
	mkdir -p $(DEPENDENCY_BUILD_DIRECTORY_ZLIB) && \
	cd $(DEPENDENCY_BUILD_DIRECTORY_ZLIB) && \
	PKG_CONFIG_PATH=$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/pkgconfig \
	CFLAGS="-O2" \
	CROSS_PREFIX="$(TOOL_TRIPLET_PREFIX)" \
	$(DEPENDENCY_SOURCE_DIRECTORY_ZLIB)/configure \
		--prefix="$(DEPENDENCY_OUTPUT_DIRECTORY)" \
		--static \
	&& \
	$(MAKE) && \
	$(MAKE) install

$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/liblzma.a: | $(DEPENDENCY_SOURCE_DIRECTORY_XZ) $(DEPENDENCY_OUTPUT_DIRECTORY)
	mkdir -p $(DEPENDENCY_BUILD_DIRECTORY_XZ) && \
	cd $(DEPENDENCY_BUILD_DIRECTORY_XZ) && \
	PKG_CONFIG_PATH=$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/pkgconfig \
	$(DEPENDENCY_SOURCE_DIRECTORY_XZ)/configure \
		CFLAGS="-O2" \
		--prefix="$(DEPENDENCY_OUTPUT_DIRECTORY)" \
		--enable-threads=no \
		--enable-unaligned-access=no \
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

$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/liblzo2.a: | $(DEPENDENCY_SOURCE_DIRECTORY_LZO) $(DEPENDENCY_OUTPUT_DIRECTORY)
	mkdir -p $(DEPENDENCY_BUILD_DIRECTORY_LZO) && \
	cd $(DEPENDENCY_BUILD_DIRECTORY_LZO) && \
	PKG_CONFIG_PATH=$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/pkgconfig \
	$(DEPENDENCY_SOURCE_DIRECTORY_LZO)/configure \
		CFLAGS="-O2" \
		--prefix="$(DEPENDENCY_OUTPUT_DIRECTORY)" \
		--enable-shared=no \
		--enable-static=yes \
		--host=$(patsubst %-,%,$(TOOL_TRIPLET_PREFIX)) \
	&& \
	$(MAKE) && \
	$(MAKE) install

$(DEPENDENCY_SOURCE_DIRECTORY_LZ4)/lib/liblz4.a: | $(DEPENDENCY_SOURCE_DIRECTORY_LZ4)
	cd $(DEPENDENCY_SOURCE_DIRECTORY_LZ4) && \
	$(MAKE) CC=$(CC) AR=$(AR) LD=$(LD) WINDRES=$(WINDRES) TARGET_OS=Windows CFLAGS="-O2" TARGET_ARCH= lib

$(DEPENDENCY_SOURCE_DIRECTORY_ZSTD)/lib/libzstd.a: | $(DEPENDENCY_SOURCE_DIRECTORY_ZSTD)
	cd $(DEPENDENCY_SOURCE_DIRECTORY_ZSTD)/lib && \
	$(MAKE) CC=$(CC) AR=$(AR) LD=$(LD) WINDRES=$(WINDRES) TARGET_OS=Windows TARGET_SYSTEM=Windows_NT CFLAGS="-O2" TARGET_ARCH= libzstd.a
