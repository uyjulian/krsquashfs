
SOURCES += storage.cpp CharacterSet.cpp
SOURCES += external/libsquash/src/cache.c external/libsquash/src/decompress.c external/libsquash/src/dir.c external/libsquash/src/dirent.c external/libsquash/src/fd.c external/libsquash/src/file.c external/libsquash/src/fs.c external/libsquash/src/hash.c external/libsquash/src/mutex.c external/libsquash/src/nonstd-makedev.c external/libsquash/src/nonstd-stat.c external/libsquash/src/private.c external/libsquash/src/readlink.c external/libsquash/src/scandir.c external/libsquash/src/stack.c external/libsquash/src/stat.c external/libsquash/src/table.c external/libsquash/src/traverse.c external/libsquash/src/util.c

INCFLAGS += -Iexternal/libsquash/include
LDLIBS += -luuid

PROJECT_BASENAME = krsquashfs

include external/ncbind/Rules.lib.make
