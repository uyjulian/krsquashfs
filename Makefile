
DEPENDENCY_OUTPUT_DIRECTORY := $(shell realpath build-libraries)

EXTLIBS += $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/liblzma.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/liblzo2.a external/lz4/lib/liblz4.a external/zstd/lib/libzstd.a

SOURCES += external/zlib/adler32.c external/zlib/compress.c external/zlib/crc32.c external/zlib/deflate.c external/zlib/gzclose.c external/zlib/gzlib.c external/zlib/gzread.c external/zlib/gzwrite.c external/zlib/infback.c external/zlib/inffast.c external/zlib/inflate.c external/zlib/inftrees.c external/zlib/trees.c external/zlib/uncompr.c external/zlib/zutil.c
SOURCES += $(EXTLIBS)
BASESOURCES += storage.cpp CharacterSet.cpp
BASESOURCES += external/libsquash/src/cache.c external/libsquash/src/decompress.c external/libsquash/src/dir.c external/libsquash/src/dirent.c external/libsquash/src/fd.c external/libsquash/src/file.c external/libsquash/src/fs.c external/libsquash/src/hash.c external/libsquash/src/mutex.c external/libsquash/src/nonstd-makedev.c external/libsquash/src/nonstd-stat.c external/libsquash/src/private.c external/libsquash/src/readlink.c external/libsquash/src/scandir.c external/libsquash/src/stack.c external/libsquash/src/stat.c external/libsquash/src/table.c external/libsquash/src/traverse.c external/libsquash/src/util.c
SOURCES += $(BASESOURCES)

INCFLAGS += -I$(DEPENDENCY_OUTPUT_DIRECTORY)/include
INCFLAGS += -Iexternal/zlib
INCFLAGS += -Iexternal/lz4/lib
INCFLAGS += -Iexternal/zstd/lib
INCFLAGS += -Iexternal/libsquash/include
LDLIBS += -luuid

PROJECT_BASENAME = krsquashfs

include external/ncbind/Rules.lib.make

$(BASESOURCES): $(EXTLIBS)

clean::
	rm -r $(DEPENDENCY_OUTPUT_DIRECTORY)
	$(MAKE) -C external/xz clean
	$(MAKE) -C external/lzo clean
	$(MAKE) -C external/lz4 clean
	$(MAKE) -C external/zstd clean

$(DEPENDENCY_OUTPUT_DIRECTORY):
	mkdir -p $(DEPENDENCY_OUTPUT_DIRECTORY)

external/xz/configure:
	cd external/xz && \
	git reset --hard && \
	NOCONFIGURE=1 ./autogen.sh

$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/liblzma.a: $(DEPENDENCY_OUTPUT_DIRECTORY) external/xz/configure
	cd external/xz && \
	PKG_CONFIG_PATH=$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/pkgconfig \
	./configure \
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
		--host=i686-w64-mingw32 \
	&& \
	$(MAKE) && \
	$(MAKE) install

$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/liblzo2.a: $(DEPENDENCY_OUTPUT_DIRECTORY)
	cd external/lzo && \
	PKG_CONFIG_PATH=$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/pkgconfig \
	./configure \
		CFLAGS="-O2" \
		--prefix="$(DEPENDENCY_OUTPUT_DIRECTORY)" \
		--enable-shared=no \
		--enable-static=yes \
		--host=i686-w64-mingw32 \
	&& \
	$(MAKE) && \
	$(MAKE) install

external/lz4/lib/liblz4.a:
	cd external/lz4 && \
	$(MAKE) CC=$(CC) AR=$(AR) LD=$(LD) WINDRES=$(WINDRES) TARGET_OS=Windows CFLAGS="-O2" lib

external/zstd/lib/libzstd.a:
	cd external/zstd/lib && \
	$(MAKE) CC=$(CC) AR=$(AR) LD=$(LD) WINDRES=$(WINDRES) TARGET_OS=Windows TARGET_SYSTEM=Windows_NT CFLAGS="-O2" libzstd.a
