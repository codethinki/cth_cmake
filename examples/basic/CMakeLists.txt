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
