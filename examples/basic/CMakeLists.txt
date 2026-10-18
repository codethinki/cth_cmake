cmake_minimum_required(VERSION 4.0.0)

project(basic_example LANGUAGES CXX VERSION 1.0.0)

#include everything
include(cth_setup_utilities)
include(cth_target_utilities)
include(cth_install_utilities)


cth_set_latest_c_cpp_standard()


#simple target
cth_glob_cpp(EXAMPLE_PUBLIC_SRC "incl")
cth_glob_cpp(EXAMPLE_PRIVATE_SRC "src")

find_package(range-v3 CONFIG REQUIRED)

add_executable(basic_example_exec ${EXAMPLE_PUBLIC_SRC} ${EXAMPLE_PRIVATE_SRC})

target_include_directories(
	basic_example_exec
	PUBLIC "incl"
)

target_link_libraries(basic_example_exec PRIVATE range-v3)


#optional subdirectories
cth_add_subdirectory(optional BASIC_EXAMPLE_OPTIONAL)
cth_assert_target(basic_example_optional REASON "cth_add_subdirectory must add a subdirectory that is ON")

set(BASIC_EXAMPLE_TRUE TRUE)
cth_add_subdirectory(enabled BASIC_EXAMPLE_ENABLED BASIC_EXAMPLE_TRUE)
cth_assert_target(basic_example_enabled REASON "cth_add_subdirectory must evaluate a variable default")

cth_add_subdirectory(unused BASIC_EXAMPLE_UNUSED_DEFAULT OFF)
cth_add_subdirectory(unused BASIC_EXAMPLE_UNUSED_UNDEFINED BASIC_EXAMPLE_UNDEFINED)

set(BASIC_EXAMPLE_UNUSED_SET OFF)
cth_add_subdirectory(unused BASIC_EXAMPLE_UNUSED_SET)

enable_testing()
add_test(NAME basic_example_exec COMMAND basic_example_exec)
