include(cth_assertions)

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

function(cth_enable_build_cache)
    cth_assert_program(buildcache)

    message(STATUS "Enabling buildcache globally: ${BUILDCACHE_PROGRAM}")

    set(CMAKE_C_COMPILER_LAUNCHER "${BUILDCACHE_PROGRAM}" PARENT_SCOPE)
    set(CMAKE_CXX_COMPILER_LAUNCHER "${BUILDCACHE_PROGRAM}" PARENT_SCOPE)
endfunction()