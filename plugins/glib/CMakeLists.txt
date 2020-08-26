cmake_minimum_required(VERSION 3.5)

project(glib)
set(CMAKE_CXX_STANDARD 14)

if (${CMAKE_SYSTEM_NAME} MATCHES "Android")
    include(ndk-stl-config.cmake)
    string(FIND ${ANDROID_ABI} 64 HAS_64)

    link_directories(
            thirdparties/mruby/lib/android/${ANDROID_ABI}
            thirdparties/v8/${ANDROID_ABI}
    )
elseif (${CMAKE_SYSTEM_NAME} MATCHES "iOS") 
    set(CMAKE_THREAD_LIBS_INIT "-lpthread")
    set(CMAKE_HAVE_THREADS_LIBRARY 1)
    set(CMAKE_USE_WIN32_THREADS_INIT 0)
    set(CMAKE_USE_PTHREADS_INIT 1)

    link_directories(
            thirdparties/mruby/lib/ios
    )
endif()
set(LIB_TYPE SHARED)

if(HAS_64 EQUAL -1)

else()
    add_definitions(-DV8_COMPRESS_POINTERS)
endif()
add_definitions(-DDEBUG)
include_directories(
        src/gcore
        thirdparties/mruby/include
        thirdparties/include
        thirdparties/libgit2/include
        thirdparties/v8/include
        thirdparties/
        thirdparties/secp256k1/include
        thirdparties/sha256
)

add_subdirectory(thirdparties/sqlite3)

add_definitions(-DUSING_SCRIPT)

set(CORE_SRC 
        src/gcore/core/IMP.cpp
        src/gcore/core/script/Script.cpp
        src/gcore/script/dart/DartScript.cpp
        src/gcore/script/ruby/RubyScript.cpp
)
if (${CMAKE_SYSTEM_NAME} MATCHES "Android")
set(CORE_SRC ${CORE_SRC} src/gcore/script/v8/V8Script.cpp)
elseif (${CMAKE_SYSTEM_NAME} MATCHES "iOS") 
set(CORE_SRC ${CORE_SRC} src/gcore/script/js_core/JSCoreScript.mm)
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

        src/shelf/main/Collection.cpp
        src/shelf/main/Context.cpp
        src/shelf/main/Project.cpp
        src/shelf/main/DataItem.cpp
        src/shelf/main/LibraryContext.cpp
        src/shelf/main/Settings.cpp

        thirdparties/sha1/sha1.c

        src/shelf/utils/dart/DartRequest.cpp
        src/shelf/utils/dart/DartPlatform.cpp
        src/shelf/utils/JSON.cpp
        src/shelf/utils/YAML.cpp
        src/shelf/utils/GitRepository.cpp
        src/shelf/utils/SharedData.cpp
        src/shelf/utils/Encoder.cpp
        src/shelf/utils/GumboParser.cpp

        src/shelf/utils/database/SQLite.cpp
        src/shelf/utils/database/Model.cpp
        src/shelf/utils/database/DBMaker.cpp
        src/shelf/utils/Bit64.cpp
        src/shelf/utils/Error.cpp
        src/shelf/utils/ScriptContext.cpp

        src/shelf/models/GitLibrary.cpp
        src/shelf/models/KeyValue.cpp
        src/shelf/models/BookData.cpp
        src/shelf/models/CollectionData.cpp
        src/shelf/models/SearchData.cpp
        src/shelf/glib.cpp
)

set(GLIB_LIBS

        core
        git2
        sqlite3
        bit64
        iconv
        gumbo
        gumbo_query
        secp256k1
        yaml
        sha256
        mruby
        onigmo
)

if (${CMAKE_SYSTEM_NAME} MATCHES "Android")
set(GLIB_SRC ${GLIB_SRC} src/shelf/dart_main_android.cpp)
set(GLIB_LIBS ${GLIB_LIBS} 
        log
        v8.cr
        v8_libplatform.cr
)
elseif(${CMAKE_SYSTEM_NAME} MATCHES "iOS")
set(GLIB_SRC ${GLIB_SRC} src/shelf/dart_main_ios.mm)
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

if (${CMAKE_SYSTEM_NAME} MATCHES "Android")
file(GLOB ICONV_SRCLIB thirdparties/iconv/src/*.c)

add_library(
        iconv
        STATIC

        ${ICONV_SRCLIB}
        thirdparties/iconv/src/uniwidth/width.c
)
target_include_directories(
        iconv
        PRIVATE
        thirdparties/iconv/src
)
target_include_directories(
        iconv
        PUBLIC
        thirdparties/iconv/include
)
endif()

file(GLOB GUMBO_SRC thirdparties/gumbo/*.c)

add_library(
        gumbo
        STATIC
        ${GUMBO_SRC}
)

include_directories(
        thirdparties/gumbo
)

file(GLOB GUMBO_QUERY_SRC thirdparties/gumbo-query/*.cpp)

add_library(
        gumbo_query
        STATIC
        ${GUMBO_QUERY_SRC}
)

add_subdirectory(thirdparties/libgit2)

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

file(GLOB YAML_SRC thirdparties/libyaml/src/*.c)

add_library(
        yaml
        STATIC

        ${YAML_SRC}
)

target_include_directories(
        yaml
        PUBLIC
        thirdparties/libyaml/include
)

target_compile_definitions(
        yaml
        PRIVATE
        -DHAVE_CONFIG_H=1
)

file(GLOB ONIGMO_SRC thirdparties/onigmo/*.c thirdparties/onigmo/enc/*.c)

add_library(
        onigmo
        STATIC
        ${ONIGMO_SRC}
)
target_include_directories(
        onigmo
        PRIVATE
        thirdparties/onigmo/
)
target_compile_definitions(
        onigmo
        PRIVATE
        -DHAVE_CONFIG_H=1
)

target_link_libraries(
        glib
        PUBLIC

        ${GLIB_LIBS}
)

if(${CMAKE_SYSTEM_NAME} MATCHES "iOS")
set_target_properties(glib PROPERTIES XCODE_ATTRIBUTE_ENABLE_BITCODE "NO")
set_target_properties(core PROPERTIES CLANG_ENABLE_OBJC_ARC "YES")
endif()