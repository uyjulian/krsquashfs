
BASESOURCES += storage.cpp CharacterSet.cpp
BASESOURCES += external/libsquash/src/cache.c external/libsquash/src/decompress.c external/libsquash/src/dir.c external/libsquash/src/dirent.c external/libsquash/src/fd.c external/libsquash/src/file.c external/libsquash/src/fs.c external/libsquash/src/hash.c external/libsquash/src/mutex.c external/libsquash/src/nonstd-makedev.c external/libsquash/src/nonstd-stat.c external/libsquash/src/private.c external/libsquash/src/readlink.c external/libsquash/src/scandir.c external/libsquash/src/stack.c external/libsquash/src/stat.c external/libsquash/src/table.c external/libsquash/src/traverse.c external/libsquash/src/util.c
SOURCES += $(BASESOURCES)

INCFLAGS += -Iexternal/libsquash/include
LDLIBS += -luuid

PROJECT_BASENAME = krsquashfs

include external/ncbind/Rules.lib.make

DEPENDENCY_BUILD_DIRECTORY_THIRD_PARTY_CMAKE := $(DEPENDENCY_BUILD_DIRECTORY)/third_party_cmake

EXTLIBS += $(DEPENDENCY_BUILD_DIRECTORY_THIRD_PARTY_CMAKE)/build-libraries/lib/libthird_party_cmake.a
SOURCES += $(EXTLIBS)
OBJECTS += $(EXTLIBS)
LDLIBS += $(EXTLIBS)

INCFLAGS += -I$(DEPENDENCY_BUILD_DIRECTORY_THIRD_PARTY_CMAKE)/build-libraries/include

$(DEPENDENCY_BUILD_DIRECTORY_THIRD_PARTY_CMAKE)/build-libraries/lib/libthird_party_cmake.a:
	cmake \
		-S third_party_cmake \
		-B $(DEPENDENCY_BUILD_DIRECTORY_THIRD_PARTY_CMAKE) \
		-DCMAKE_SYSTEM_NAME=Windows \
		-DCMAKE_SYSTEM_PROCESSOR=$(TARGET_CMAKE_SYSTEM_PROCESSOR) \
		-DCMAKE_FIND_ROOT_PATH=/dev/null \
		-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
		-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
		-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
		-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
		-DCMAKE_DISABLE_FIND_PACKAGE_PkgConfig=TRUE \
		-DCMAKE_C_COMPILER=$(CC) \
		-DCMAKE_CXX_COMPILER=$(CXX) \
		-DCMAKE_RC_COMPILER=$(WINDRES) \
		-DCMAKE_BUILD_TYPE=Release \
		&& \
	cmake --build $(DEPENDENCY_BUILD_DIRECTORY_THIRD_PARTY_CMAKE)

$(BASESOURCES): $(EXTLIBS)
