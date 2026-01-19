cmake_minimum_required(VERSION 4.0.0)

message(STATUS "----cth_cmake toolchain----")

#append cmake dir to module path
set(CTH_CMAKE_LIBRARY_DIR ${CMAKE_CURRENT_LIST_DIR})
list(APPEND CMAKE_MODULE_PATH "${CTH_CMAKE_LIBRARY_DIR}")
set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}" CACHE STRING "Search path for CMake modules" FORCE)
message(STATUS "Appended ${CTH_CMAKE_LIBRARY_DIR} to module path")

include(cth_assertions)


#enable BuildCache
if(NOT CTH_DISABLE_FULL_BUILD_CACHE)
    include(cth_tool_utilities)
    cth_enable_build_cache()
endif()

#delegate to vcpkg
if(NOT CTH_DISABLE_VCPKG_INTEGRATION)
    cth_assert_program(vcpkg)
    cth_assert_not_empty("$ENV{VCPKG_ROOT}")

    include("$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake")
endif()
