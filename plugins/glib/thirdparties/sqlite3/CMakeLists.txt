cmake_minimum_required(VERSION 3.5)

file(GLOB SQL_SRC *.c)

add_library(
    sqlite3

    STATIC

    ${SQL_SRC}
)