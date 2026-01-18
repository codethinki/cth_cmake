include(cth_assertions)

# cth_enable_build_cache
# Enables BuildCache globally by setting compiler launcher variables
function(cth_enable_build_cache)
    cth_assert_program(buildcache)

    message(STATUS "Enabling buildcache globally: ${BUILDCACHE_PROGRAM}")

    set(CMAKE_C_COMPILER_LAUNCHER "${BUILDCACHE_PROGRAM}" PARENT_SCOPE)
    set(CMAKE_CXX_COMPILER_LAUNCHER "${BUILDCACHE_PROGRAM}" PARENT_SCOPE)
endfunction()