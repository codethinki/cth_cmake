# Copyright (c) 2026 Lukas Thomann
# Licensed under the MIT License

#[[.rst:
GLSL language
-------------

   .. code-block:: cmake

      enable_language(GLSL)

      add_library(<name>_shaders OBJECT <shaders...>)
      target_link_libraries(<name>_shaders PRIVATE <targets with shader include dirs...>)

   Compiles GLSL shaders to SPIR-V with ``glslc``, like a built-in language.

   - sources: the shader stage extensions of glslc: ``vert`` ``frag`` ``comp`` ``geom`` ``tesc`` ``tese``
     ``mesh`` ``task`` ``rgen`` ``rint`` ``rahit`` ``rchit`` ``rmiss`` ``rcall``
   - other files, e.g. ``.glsl`` includes, can be in the source list, they are not compiled
   - objects: ``<source name>.spv``, e.g. ``a.vert`` -> ``a.vert.spv``, ``$<TARGET_OBJECTS:<name>_shaders>`` lists
     them
   - include directories, compile definitions and compile options of the target and of the targets it links reach
     glslc as ``-I``, ``-D`` and options
   - a changed include compiles the shader again: glslc writes a depfile

   .. variable:: CMAKE_GLSL_COMPILER

      Cache variable, the glslc compatible compiler. Set it to use another compiler.
      Not set -> the first ``glslc`` of ``$ENV{VULKAN_SDK}/bin``, ``$ENV{VULKAN_SDK}/Bin``, then the ``PATH`` and
      the other paths of ``find_program()``.
      No compiler -> configuration terminates with FATAL_ERROR.

   .. variable:: CMAKE_GLSL_FLAGS

      Cache variables ``CMAKE_GLSL_FLAGS`` and ``CMAKE_GLSL_FLAGS_<CONFIG>``, the flags of the user, like
      ``CMAKE_CXX_FLAGS``. Initialized from ``$ENV{GLSLFLAGS}`` and per configuration:

      - Debug: ``-g``
      - Release: ``-O``
      - RelWithDebInfo: ``-O -g``
      - MinSizeRel: ``-Os``

      The configuration decides the optimization, like for C++: no ``-O`` of a target.

   .. note::
      A flag that the project requires, e.g. the target environment, is a compile option, not a user flag:
      ``add_compile_options($<$<COMPILE_LANGUAGE:GLSL>:--target-env=vulkan1.3>)``.

   .. warning::
      Put shaders in an OBJECT library of their own: a STATIC library archives the ``.spv`` files, an executable
      or a SHARED library passes them to the linker.

   .. note::
      Compile options for every language reach glslc too: guard them with ``$<COMPILE_LANGUAGE:C,CXX>``.

#]]

include(cth_tool_utilities)

cth_find_program(
    CMAKE_GLSL_COMPILER glslc OPTIONAL
    HINTS ENV VULKAN_SDK
    PATH_SUFFIXES bin Bin
    DOC "glslc compatible GLSL compiler"
)
cth_assert_true(CMAKE_GLSL_COMPILER
    REASON "glslc not found: install the Vulkan SDK, add glslc to the PATH or set CMAKE_GLSL_COMPILER")

# the next configurations load this file instead of this module, CMAKE_GLSL_COMPILER stays in the cache only:
# a changed cache variable takes effect
file(WRITE "${CMAKE_PLATFORM_INFO_DIR}/CMakeGLSLCompiler.cmake"
    "set(CMAKE_GLSL_COMPILER_LOADED 1)\n"
    "set(CMAKE_GLSL_SOURCE_FILE_EXTENSIONS vert;frag;comp;geom;tesc;tese;mesh;task;rgen;rint;rahit;rchit;rmiss;rcall)\n"
    "set(CMAKE_GLSL_OUTPUT_EXTENSION .spv)\n"
)
