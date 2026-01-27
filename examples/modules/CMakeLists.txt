cmake_minimum_required(VERSION 4.0.0)

project(cpp_modules LANGUAGES CXX VERSION 1.0.0)

include(cth_setup_utilities)
include(cth_target_utilities)

cth_set_latest_c_cpp_standard()

#simple project
cth_glob_cppm(MODULES_SRC "modules")
cth_glob_cpp(SRC "src")

add_executable(modules_executable ${SRC})

message(STATUS "found modules: ${MODULES_SRC}")
message(STATUS "found sources: ${SRC}")


cth_target_add_modules(modules_executable PUBLIC ${MODULES_SRC})




