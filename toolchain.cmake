cmake_minimum_required(4)

#append cmake dir to module path
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}")
message("Appended cth_cmake to module path")

include(cth_assertions)
include(cth_tool_utilities)



#delegate to vcpkg
cth_assert_program(vcpkg)
cth_assert_not_empty("$ENV{VCPKG_ROOT}")

include("$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake")
