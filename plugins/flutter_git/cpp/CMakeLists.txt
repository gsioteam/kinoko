cmake_minimum_required(VERSION 3.5)

project(flutter_git)

add_subdirectory(openssl)
set(OPENSSL_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/openssl/include)

include_directories(
        libgit2/include
)

add_subdirectory(libgit2)

add_library(
        flutter_git

        SHARED

        main.c
        bmt.c
)

target_link_libraries(
        flutter_git

        PUBLIC

        git2
)