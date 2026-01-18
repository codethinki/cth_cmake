cmake_minimum_required(VERSION 4.0.0)

#append cmake dir to module path
set(CTH_CMAKE_LIBRARY_DIR ${CMAKE_CURRENT_LIST_DIR})
list(APPEND CMAKE_MODULE_PATH "${CTH_CMAKE_LIBRARY_DIR}")
message("Appended ${CTH_CMAKE_LIBRARY_DIR} to module path")

include(cth_assertions)
include(cth_tool_utilities)



#delegate to vcpkg
cth_assert_program(vcpkg)
cth_assert_not_empty("$ENV{VCPKG_ROOT}")

include("$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake")
