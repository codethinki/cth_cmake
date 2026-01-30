cmake_minimum_required(VERSION 4.0.0)

message(STATUS "---- cth_cmake toolchain ----")

#append cmake dir to module path
set(CTH_CMAKE_LIBRARY_DIR ${CMAKE_CURRENT_LIST_DIR})
list(APPEND CMAKE_MODULE_PATH "${CTH_CMAKE_LIBRARY_DIR}")
message(STATUS "appended ${CTH_CMAKE_LIBRARY_DIR} to cmake module path")

include(cth_assertions)
include(cth_tool_utilities)

#delegate to vcpkg
if(NOT CTH_DISABLE_VCPKG_INTEGRATION)

    cth_assert_not_empty("$ENV{VCPKG_ROOT}")
    cth_find_program(vcpkg HINT "$ENV{VCPKG_ROOT}")

    message(STATUS "handing off to vcpkg")
    include("$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake")
endif()
