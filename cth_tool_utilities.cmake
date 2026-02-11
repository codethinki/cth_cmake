# Copyright (c) 2026 Lukas Thomann
# Licensed under the MIT License

include(cth_assertions)

#[[.rst:
.. command:: cth_find_optional_program

   .. code-block:: cmake

      cth_find_optional_program(<out_var> <prog> [args...])

   Locates an external program and exports its path to the parent scope.

   :param OUT_VAR variable to export program path to
   :param prog: Name of the program to find
   :type prog: string
   :param args: Additional arguments to pass to find_program (e.g., PATHS, HINTS)
   :type args: optional arguments

   :post: <OUT_VAR> variable is set in PARENT_SCOPE with the full path to the program if found, or an empty string if not found

   .. note::
      Unlike ``cth_find_program()``, this function does not error if the program is not found.
      Check if the result variable is empty to determine if the program was found.

#]]
function(cth_find_optional_program OUT_VAR prog)
    
    find_program(${OUT_VAR} "${prog}" ${ARGN})
    
    set(${OUT_VAR} "${${OUT_VAR}}" PARENT_SCOPE)
endfunction()

#[[.rst:
.. command:: cth_find_program

   .. code-block:: cmake

      cth_find_program(<out_var> <prog> [args...])

   Locates a required external program and exports its path to the parent scope.
   Terminates configuration with FATAL_ERROR if not found.

   :param OUT_VAR variable to export program path to
   :param prog: Name of the program to find
   :param args: Additional arguments to pass to find_program

   :post: <OUT_VAR> variable is set in PARENT_SCOPE with the full path to the program, or configuration terminates with FATAL_ERROR if not found

   .. seealso::
      See ``cth_find_optional_program()`` for a variant that does not error if the program is not found.

#]]
function(cth_find_program OUT_VAR prog)
    cth_find_optional_program(${OUT_VAR} "${prog}" ${ARGN})
    
    cth_assert_true(${OUT_VAR} REASON "Program '${prog}' not found")
    
    set(${OUT_VAR} "${${OUT_VAR}}" PARENT_SCOPE)
endfunction()

#[[.rst:
.. command:: cth_enable_build_cache

   .. code-block:: cmake

      cth_enable_build_cache()

   Enables BuildCache globally for all targets by setting compiler launcher variables.

   :pre: buildcache program is found in PATH
   :post: CMAKE_C_COMPILER_LAUNCHER and CMAKE_CXX_COMPILER_LAUNCHER are set to buildcache in PARENT_SCOPE

   .. note::
      This affects ALL targets in the current scope and below.
      For per-target control, use ``cth_target_enable_build_cache()`` instead.

   .. warning::
      BuildCache must be installed and available in PATH.
      The function will fail with FATAL_ERROR if buildcache is not found.

   .. seealso::
      Use ``cth_target_enable_build_cache()`` from cth_target_utilities for per-target control.

#]]
function(cth_enable_build_cache)
    cth_find_program(BUILDCACHE_EXECUTABLE buildcache)

    message(STATUS "Enabling buildcache globally: ${BUILDCACHE_EXECUTABLE}")

    set(CMAKE_C_COMPILER_LAUNCHER "${BUILDCACHE_EXECUTABLE}" PARENT_SCOPE)
    set(CMAKE_CXX_COMPILER_LAUNCHER "${BUILDCACHE_EXECUTABLE}" PARENT_SCOPE)
endfunction()

#[[.rst:
.. command:: cth_find_opt_clang_format

   .. code-block:: cmake

      cth_find_opt_clang_format()

   Locates the clang-format executable and exports its path to the parent scope.
   Does not error if clang-format is not found.

   :post: CLANG_FORMAT_EXECUTABLE is set in PARENT_SCOPE with the full path to clang-format, or an empty string if not found

   .. note::
      Check if CLANG_FORMAT_EXECUTABLE is empty to determine if clang-format was found.

   .. seealso::
      Use ``cth_add_clang_format_target()`` from cth_target_utilities to create a format target.

#]]
function(cth_find_opt_clang_format)
   cth_find_optional_program(CLANG_FORMAT_EXECUTABLE clang-format)
   
   if(CLANG_FORMAT_EXECUTABLE)
      message(STATUS "Found external clang-format: ${CLANG_FORMAT_EXECUTABLE}")
   endif()

   set(CLANG_FORMAT_EXECUTABLE ${CLANG_FORMAT_EXECUTABLE} PARENT_SCOPE)
endfunction()

#[[.rst:
.. command:: cth_find_clang_format

   .. code-block:: cmake

      cth_find_clang_format()

   Locates a required clang-format executable and exports its path to the parent scope.
   Terminates configuration with FATAL_ERROR if not found.

   :post: CLANG_FORMAT_EXECUTABLE is set in PARENT_SCOPE with the full path to clang-format, or configuration terminates with FATAL_ERROR

   .. seealso::
      See ``cth_find_opt_clang_format()`` for a variant that does not error if clang-format is not found.
      Use ``cth_add_clang_format_target()`` from cth_target_utilities to create a format target.

#]]
function(cth_find_clang_format)
   cth_find_opt_clang_format()
   
   cth_assert_true(CLANG_FORMAT_EXECUTABLE REASON "clang-format not found")
   
   set(CLANG_FORMAT_EXECUTABLE ${CLANG_FORMAT_EXECUTABLE} PARENT_SCOPE)
endfunction()