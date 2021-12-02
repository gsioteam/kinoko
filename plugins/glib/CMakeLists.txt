cmake_minimum_required(VERSION 3.5)

project(glib)
set(CMAKE_CXX_STANDARD 14)

if (${CMAKE_SYSTEM_NAME} MATCHES "Android")
    include(ndk-stl-config.cmake)
    string(FIND ${ANDROID_ABI} 64 HAS_64)

elseif (${CMAKE_SYSTEM_NAME} MATCHES "iOS") 
    set(CMAKE_THREAD_LIBS_INIT "-lpthread")
    set(CMAKE_HAVE_THREADS_LIBRARY 1)
    set(CMAKE_USE_WIN32_THREADS_INIT 0)
    set(CMAKE_USE_PTHREADS_INIT 1)

endif()

if(HAS_64 EQUAL -1)

else()
    add_definitions(-DV8_COMPRESS_POINTERS)
endif()
add_definitions(-DDEBUG)
include_directories(
        src/gcore
        thirdparties/
        thirdparties/sha256
        thirdparties/secp256k1/include
)

add_subdirectory(thirdparties/sqlite3)

add_definitions(-DUSING_SCRIPT)

set(CORE_SRC 
        src/gcore/core/IMP.cpp
        src/gcore/core/script/Script.cpp
        src/gcore/script/dart/DartScript.cpp
)
if (${CMAKE_SYSTEM_NAME} MATCHES "Android")
# set(CORE_SRC ${CORE_SRC} src/gcore/script/v8/V8Script.cpp)
#set(CORE_SRC
#
#        ${CORE_SRC}
#        src/gcore/script/quickjs/quickjs_ext.c
#        src/gcore/script/quickjs/libbf.c
#        src/gcore/script/quickjs/qjscalc.c
#        src/gcore/script/quickjs/libregexp.c
#        src/gcore/script/quickjs/libunicode.c
#        src/gcore/script/quickjs/cutils.c
#        )
add_definitions(-DCONFIG_VERSION=\"qjs_u\" -DEMSCRIPTEN -DDUMP_LEAKS -DCONFIG_BIGNUM)
elseif (${CMAKE_SYSTEM_NAME} MATCHES "iOS") 
endif()

add_library(
        core
        # Sets the library as a shared library.
        STATIC

        # Provides a relative path to your source file(s).
        ${CORE_SRC}
)

add_library(
        bit64

        STATIC
        thirdparties/bit64/bit64.cpp
)

set(GLIB_SRC

        src/application/main/DataItem.cpp

        thirdparties/sha1/sha1.c

        src/application/utils/database/SQLite.cpp
        src/application/utils/database/DBMaker.cpp
        src/application/utils/database/Model.cpp
        src/application/utils/Bit64.cpp

        src/application/models/KeyValue.cpp
        src/application/models/CollectionData.cpp
        src/application/models/BookData.cpp
        src/application/glib.cpp
)

set(GLIB_LIBS

        core
        sqlite3
        bit64
        secp256k1
        sha256
)

if (${CMAKE_SYSTEM_NAME} MATCHES "Android")
    set(GLIB_SRC ${GLIB_SRC} src/application/dart_main_android.cpp)
    set(GLIB_LIBS ${GLIB_LIBS}
        log
#        v8.cr
#        v8_libplatform.cr
    )
    set(LIB_TYPE SHARED)
elseif(${CMAKE_SYSTEM_NAME} MATCHES "iOS")
    set(GLIB_SRC ${GLIB_SRC} src/application/dart_main_ios.mm)
    set(LIB_TYPE STATIC)
endif()

add_library(
        glib
        ${LIB_TYPE}

        ${GLIB_SRC}
)

target_include_directories(
        glib
        PRIVATE

        thirdparties/sqlite3
        thirdparties/sha1
)

#set(OPENSSL_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/thirdparties/openssl/openssl)
#set(OPENSSL_INCLUDE_DIR ${OPENSSL_ROOT}/include)
#if (${CMAKE_SYSTEM_NAME} MATCHES "Android")
#    set(OPENSSL_CRYPTO_LIBRARY ${OPENSSL_ROOT}/android/${ANDROID_ABI}/lib/libcrypto.a)
#    set(OPENSSL_SSL_LIBRARY ${OPENSSL_ROOT}/android/${ANDROID_ABI}/lib/libssl.a)
#    set(OPENSSL_LIBRARIES ${OPENSSL_ROOT}/android/${ANDROID_ABI}/lib)
#elseif(${CMAKE_SYSTEM_NAME} MATCHES "iOS")
#    set(OPENSSL_CRYPTO_LIBRARY ${OPENSSL_ROOT}/ios/lib/libcrypto.a)
#    set(OPENSSL_SSL_LIBRARY ${OPENSSL_ROOT}/ios/lib/libssl.a)
#    set(OPENSSL_LIBRARIES ${OPENSSL_ROOT}/ios/lib)
#    SET(GIT_USE_STAT_MTIMESPEC 1)
#endif()

add_library(
        secp256k1
        STATIC

        thirdparties/secp256k1/src/secp256k1.c
)

target_compile_definitions(
        secp256k1
        PRIVATE
        -DHAVE_CONFIG_H
)

target_include_directories(
        secp256k1
        PRIVATE

        thirdparties/secp256k1
)

add_library(
        sha256
        STATIC

        thirdparties/sha256/sha256.c
)

target_link_libraries(
        glib
        PUBLIC

        ${GLIB_LIBS}
)

if(${CMAKE_SYSTEM_NAME} MATCHES "iOS")
set_target_properties(glib 
        PROPERTIES 
        XCODE_ATTRIBUTE_ENABLE_BITCODE "NO"
)
set_target_properties(core 
        PROPERTIES 
        XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC "YES"
)
endif()