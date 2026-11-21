# Copyright (c) 2026 Lukas Thomann
# Licensed under the MIT License

# checks that the GLSL compiler compiles a simple shader, see CMakeDetermineGLSLCompiler.cmake

if(NOT CMAKE_GLSL_COMPILER_WORKS)
    set(CTH_GLSL_TEST_DIR "${CMAKE_PLATFORM_INFO_DIR}/CompilerTestGLSL")
    file(WRITE "${CTH_GLSL_TEST_DIR}/test.comp" "#version 450\nlayout(local_size_x = 1) in;\nvoid main() {}\n")

    execute_process(
        COMMAND "${CMAKE_GLSL_COMPILER}" -c "${CTH_GLSL_TEST_DIR}/test.comp" -o "${CTH_GLSL_TEST_DIR}/test.comp.spv"
        RESULT_VARIABLE CTH_GLSL_TEST_RESULT
        OUTPUT_VARIABLE CTH_GLSL_TEST_OUTPUT
        ERROR_VARIABLE CTH_GLSL_TEST_OUTPUT
    )

    if(NOT CTH_GLSL_TEST_RESULT EQUAL 0)
        message(FATAL_ERROR
            "The GLSL compiler \"${CMAKE_GLSL_COMPILER}\" does not compile a simple shader:\n${CTH_GLSL_TEST_OUTPUT}")
    endif()

    message(STATUS "Check for working GLSL compiler: ${CMAKE_GLSL_COMPILER} - works")
    set(CMAKE_GLSL_COMPILER_WORKS 1 CACHE INTERNAL "")

    unset(CTH_GLSL_TEST_DIR)
    unset(CTH_GLSL_TEST_RESULT)
    unset(CTH_GLSL_TEST_OUTPUT)
endif()
