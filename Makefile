
SOURCES += storage.cpp CharacterSet.cpp
SOURCES += external/libsquash/src/cache.c external/libsquash/src/decompress.c external/libsquash/src/dir.c external/libsquash/src/dirent.c external/libsquash/src/fd.c external/libsquash/src/file.c external/libsquash/src/fs.c external/libsquash/src/hash.c external/libsquash/src/mutex.c external/libsquash/src/nonstd-makedev.c external/libsquash/src/nonstd-stat.c external/libsquash/src/private.c external/libsquash/src/readlink.c external/libsquash/src/scandir.c external/libsquash/src/stack.c external/libsquash/src/stat.c external/libsquash/src/table.c external/libsquash/src/traverse.c external/libsquash/src/util.c
SOURCES += external/zlib/adler32.c external/zlib/compress.c external/zlib/crc32.c external/zlib/deflate.c external/zlib/gzclose.c external/zlib/gzlib.c external/zlib/gzread.c external/zlib/gzwrite.c external/zlib/infback.c external/zlib/inffast.c external/zlib/inflate.c external/zlib/inftrees.c external/zlib/trees.c external/zlib/uncompr.c external/zlib/zutil.c
LDLIBS += -luuid

INCFLAGS += -Iexternal/zlib
INCFLAGS += -Iexternal/libsquash/include

PROJECT_BASENAME = krsquashfs

include external/ncbind/Rules.lib.make
