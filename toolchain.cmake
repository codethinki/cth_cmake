# Copyright (c) 2026 Lukas Thomann
# Licensed under the MIT License

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

    cth_assert_not_empty("$ENV{VCPKG_ROOT}" REASON "VCPKG_ROOT is not set, point it at your vcpkg directory or set CTH_DISABLE_VCPKG_INTEGRATION")
    cth_assert_program(vcpkg HINTS "$ENV{VCPKG_ROOT}" REASON "vcpkg not found in VCPKG_ROOT ($ENV{VCPKG_ROOT}), run bootstrap-vcpkg there")

    message(STATUS "handing off to vcpkg")
    include("$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake")
endif()
