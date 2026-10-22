# Copyright (c) 2026 Lukas Thomann
# Licensed under the MIT License

include(cth_assertions)

#[[.rst:
.. command:: cth_set_compiler_specifics

   .. code-block:: cmake

      cth_set_compiler_specifics()

   Applies compiler-specific common flags for the project.

   :post: Compiler flags are set based on detected compiler

   .. note::
      **MSVC:**

      - Adds ``/utf-8`` flag for UTF-8 source and execution character sets

      **Other compilers (GCC, Clang):**

      - Adds ``-fexceptions`` flag to enable exception handling

#]]
function(cth_set_compiler_specifics)
   message("Using compiler ${CMAKE_CXX_COMPILER}")

   if(MSVC)
      add_compile_options(
         $<$<COMPILE_LANGUAGE:CXX>:/utf-8>
         $<$<COMPILE_LANGUAGE:CUDA>:-Xcompiler=/utf-8>
      )
   else()
      add_compile_options(-fexceptions)
   endif()
endfunction()

#[[.rst:
.. command:: cth_set_latest_c_cpp_standard

   .. code-block:: cmake

      cth_set_latest_c_cpp_standard()

   Sets the project to use the latest supported C/C++ standard.

   :post: CMAKE_CXX_STANDARD and CMAKE_C_STANDARD are set to latest supported version
   :post: CMAKE_CXX_STANDARD_REQUIRED is set to ON

   .. note::
      **MSVC:**

      - Sets C++ standard to C++23
      - Adds ``/std:c++latest`` flag for bleeding-edge features

      **Other compilers (GCC, Clang):**

      - Sets C++ standard to C++26 (experimental)

   .. note::
      C standard: C17 for MSVC, C23 for other compilers. C has no 26, a copy of the C++ standard fails.

   .. warning::
      This is a macro, not a function. Variables are set in the calling scope.

#]]
macro(cth_set_latest_c_cpp_standard)
   if(MSVC)
      set(CMAKE_CXX_STANDARD 23)
      add_compile_options($<$<COMPILE_LANGUAGE:CXX>:/std:c++latest>)
      set(CMAKE_C_STANDARD 17)
   else()
      set(CMAKE_CXX_STANDARD 26)
      set(CMAKE_C_STANDARD 23)
   endif()

   set(CMAKE_CXX_STANDARD_REQUIRED ON)
   set(CMAKE_CXX_EXTENSIONS OFF)

   message("Set cxx standard to ${CMAKE_CXX_STANDARD}")
endmacro()

#[=[.rst:
.. command:: cth_add_subdirectory

   .. code-block:: cmake

      cth_add_subdirectory(<dir> [<option> [<default>]])

   Adds a subdirectory, optionally behind an option. A parent project turns parts of a library off
   by setting the options before it adds the library.

   :param dir: Subdirectory to add, as for ``add_subdirectory()``
   :type dir: path
   :param option: Option that controls the subdirectory, omitted -> the subdirectory is always added
   :type option: string
   :param default: Value of the option if nothing sets it: ON, OFF or a variable name, evaluated with ``if()``
                   (default: ON)
   :type default: boolean or variable name

   :post: the subdirectory is added if ``option`` is ON or omitted

   .. note::
      Policy CMP0077 is NEW: a normal variable wins over the cache option,
      ``set(<option> OFF)`` before ``add_subdirectory(<library>)`` is enough.

   .. note::
      Pass a variable by name, ``WIN32`` instead of ``${WIN32}``: an undefined variable is OFF,
      its empty expansion would drop the argument and leave the default ON.

#]=]
function(cth_add_subdirectory dir)
   cth_assert_true(${ARGC} LESS_EQUAL 3 REASON "cth_add_subdirectory(<dir> [<option> [<default>]]), got: ${ARGV}")

   if(ARGC EQUAL 1)
      add_subdirectory("${dir}")
      return()
   endif()

   set(option "${ARGV1}")
   set(default ON)
   if(ARGC EQUAL 3)
      set(default OFF)
      # unquoted: a variable name is dereferenced, an empty argument is OFF
      if(NOT "${ARGV2}" STREQUAL "")
         if(${ARGV2})
            set(default ON)
         endif()
      endif()
   endif()

   option(${option} "add the ${dir} subdirectory" ${default})
   if(${option})
      add_subdirectory("${dir}")
   endif()
endfunction()
