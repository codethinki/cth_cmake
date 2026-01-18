#append cmake dir to module path
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}")
message("Appended cth_cmake to module path")

include(tool_utilities)

find_tool(buildcache)

#delegate to vcpkg
include("$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake")
