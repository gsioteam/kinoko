cmake_minimum_required(VERSION 3.5)

project(gcore)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

set(CORE_SRC
        core/script/Script.cpp
        core/IMP.cpp
        )

add_library(gcore STATIC ${CORE_SRC})

project(gn_ruby)

add_library(gn_mruby STATIC
        script/ruby/RubyScript.cpp
        )

target_include_directories(gn_mruby PUBLIC script/ruby/include)
target_link_directories(gn_mruby PUBLIC script/ruby/lib)
target_link_libraries(gn_mruby mruby)

project(gn_js)

add_library(gn_js
        STATIC
        script/javascript/V8Script.cpp
        )
target_include_directories(gn_js PUBLIC script/javascript/include)
target_link_directories(gn_js PUBLIC script/javascript/lib)
target_link_libraries(gn_js v8 v8_libplatform)

project(gcore_test)

link_libraries(gcore)

link_directories("test/libs")
include_directories("test/include")

link_libraries(gcore gmock gtest gn_mruby gn_js)

add_definitions(-DUSING_SCRIPT -DDEBUG)

include_directories(".")

set(TEST_SRC test/main.cpp test/TestObject.cpp test/TestObject.h)

add_executable(gcore_test ${TEST_SRC})

