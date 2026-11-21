# Copyright (c) 2026 Lukas Thomann
# Licensed under the MIT License

# the rules of the GLSL language, see CMakeDetermineGLSLCompiler.cmake

set(CMAKE_INCLUDE_FLAG_GLSL "-I")

# -c: SPIR-V of one shader, the stage comes from the extension
if(NOT CMAKE_GLSL_COMPILE_OBJECT)
    set(CMAKE_GLSL_COMPILE_OBJECT "<CMAKE_GLSL_COMPILER> <DEFINES> <INCLUDES> <FLAGS> -c <SOURCE> -o <OBJECT>")
endif()

# glslc writes the includes of a shader in the gcc format: a changed include compiles the shader again
set(CMAKE_DEPFILE_FLAGS_GLSL "-MD -MF <DEP_FILE>")
set(CMAKE_GLSL_DEPFILE_FORMAT gcc)
set(CMAKE_GLSL_DEPENDS_USE_COMPILER TRUE)

# the user flags, like a built-in language
set(CMAKE_GLSL_FLAGS_INIT "$ENV{GLSLFLAGS} ${CMAKE_GLSL_FLAGS_INIT}")
string(APPEND CMAKE_GLSL_FLAGS_DEBUG_INIT " -g")
string(APPEND CMAKE_GLSL_FLAGS_RELEASE_INIT " -O")
string(APPEND CMAKE_GLSL_FLAGS_RELWITHDEBINFO_INIT " -O -g")
string(APPEND CMAKE_GLSL_FLAGS_MINSIZEREL_INIT " -Os")
cmake_initialize_per_config_variable(CMAKE_GLSL_FLAGS "Flags used by the GLSL compiler")

set(CMAKE_GLSL_INFORMATION_LOADED 1)
