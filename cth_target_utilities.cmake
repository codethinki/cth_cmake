# Copyright (c) 2026 Lukas Thomann
# Licensed under the MIT License

include(cth_assertions)

#[[.rst:
.. command:: cth_glob

   .. code-block:: cmake

      cth_glob(<out_var> <sub_paths...> [PATTERNS <patterns...>] [PRESERVE_SUBPATHS])

   Recursively globs for files matching specified patterns in one or more subdirectories.

   :param out_var: Variable to append found files to
   :type out_var: string
   :param sub_paths: One or more subdirectory paths to search within
   :type sub_paths: string or list of strings
   :param PATTERNS: List of file patterns to match (e.g., "*.cpp", "*.hpp")
   :type PATTERNS: list of strings
   :param PRESERVE_SUBPATHS: Encode each result as ``<abs_path>|<rel_path>`` instead of a bare
                             path, where ``rel_path`` (filename included) is relative to the
                             ``sub_path`` the file was found under. Only valid together with
                             ``sub_paths`` and ``PATTERNS``.

   :pre: if PRESERVE_SUBPATHS is given, sub_paths and PATTERNS must both be non-empty
   :post: out_var contains the list of found files appended to existing content

   .. note::
      Uses GLOB_RECURSE with CONFIGURE_DEPENDS to ensure CMake re-runs if files change.
      Results are appended to out_var, preserving any existing content.
      When multiple paths are provided, all paths are searched and results are combined.

   .. note::
      ``PRESERVE_SUBPATHS`` encoding uses ``|`` as separator (illegal in Windows filenames, so
      unambiguous): ``sub_path=C:/x, file C:/x/y/a.txt`` -> ``"C:/x/y/a.txt|y/a.txt"``. Useful for
      callers that need to reconstruct the directory structure a file was found in relative to
      its search root (e.g. ``cth_target_attach_copy_dependency``).

#]]
function(cth_glob OUT_VAR)
    set(options PRESERVE_SUBPATHS)
    set(multiValueArgs PATTERNS)
    cmake_parse_arguments(PARSE_ARGV 1 ARG "${options}" "" "${multiValueArgs}")

    set(SUB_PATHS ${ARG_UNPARSED_ARGUMENTS})

    if(ARG_PRESERVE_SUBPATHS)
        cth_assert_not_empty("${SUB_PATHS}"
            REASON "cth_glob: PRESERVE_SUBPATHS requires at least one sub_path")
        cth_assert_not_empty("${ARG_PATTERNS}"
            REASON "cth_glob: PRESERVE_SUBPATHS is only valid in the sub_paths + PATTERNS case")

        # Glob per sub_path (instead of the single combined call below) so each result can be
        # related back to the sub_path it was found under, and encode it as "<abs_path>|<rel_path>"
        # so callers can reconstruct the directory structure downstream.
        set(FOUND_FILES "")

        foreach(SUB_PATH IN LISTS SUB_PATHS)
            if(NOT SUB_PATH)
                continue()
            endif()

            cmake_path(ABSOLUTE_PATH SUB_PATH NORMALIZE OUTPUT_VARIABLE NORMALIZED_SUB_PATH)

            set(SUB_PATH_NORMALIZED_PATTERNS "")
            foreach(PATTERN IN LISTS ARG_PATTERNS)
                set(RAW_PATTERN "${SUB_PATH}/${PATTERN}")
                cmake_path(ABSOLUTE_PATH RAW_PATTERN NORMALIZE OUTPUT_VARIABLE NORMALIZED_PATTERN)
                list(APPEND SUB_PATH_NORMALIZED_PATTERNS "${NORMALIZED_PATTERN}")
            endforeach()

            # LIST_DIRECTORIES FALSE: PATTERNS like "*" also match directory names, and directory
            # entries would otherwise show up as "found files" (breaking downstream file copies).
            file(GLOB_RECURSE SUB_PATH_FOUND_FILES
                CONFIGURE_DEPENDS
                LIST_DIRECTORIES FALSE
                ${SUB_PATH_NORMALIZED_PATTERNS}
            )

            foreach(FOUND_FILE IN LISTS SUB_PATH_FOUND_FILES)
                file(RELATIVE_PATH REL_FILE "${NORMALIZED_SUB_PATH}" "${FOUND_FILE}")
                list(APPEND FOUND_FILES "${FOUND_FILE}|${REL_FILE}")
            endforeach()
        endforeach()

        set(${OUT_VAR} ${${OUT_VAR}} ${FOUND_FILES} PARENT_SCOPE)
        return()
    endif()

    set(GLOB_PATTERNS "")

    if(SUB_PATHS AND ARG_PATTERNS)
        # Case 1: Both paths and patterns provided - generate cross-product
        foreach(SUB_PATH IN LISTS SUB_PATHS)
            foreach(PATTERN IN LISTS ARG_PATTERNS)
                if(SUB_PATH)
                    list(APPEND GLOB_PATTERNS "${SUB_PATH}/${PATTERN}")
                else()
                    list(APPEND GLOB_PATTERNS "${PATTERN}")
                endif()
            endforeach()
        endforeach()
    elseif(SUB_PATHS)
        # Case 2: Only sub_paths provided - treat them as full patterns
        set(GLOB_PATTERNS ${SUB_PATHS})
    elseif(ARG_PATTERNS)
        # Case 3: Only patterns provided - treat them as full patterns
        set(GLOB_PATTERNS ${ARG_PATTERNS})
    endif()

    # Normalize paths to prevent CONFIGURE_DEPENDS cache mismatch issues on Windows
    set(NORMALIZED_PATTERNS "")

    foreach(PATTERN IN LISTS GLOB_PATTERNS)
        cmake_path(ABSOLUTE_PATH PATTERN NORMALIZE OUTPUT_VARIABLE NORMALIZED)
        list(APPEND NORMALIZED_PATTERNS "${NORMALIZED}")
    endforeach()

    if(NORMALIZED_PATTERNS)
        file(GLOB_RECURSE FOUND_FILES
            CONFIGURE_DEPENDS
            ${NORMALIZED_PATTERNS}
        )
        set(${OUT_VAR} ${${OUT_VAR}} ${FOUND_FILES} PARENT_SCOPE)
    endif()
endfunction()

#[[.rst:
.. command:: cth_glob_cpp

   .. code-block:: cmake

      cth_glob_cpp(<out_var> <sub_paths...>)

   Recursively globs for common C++ source and header files in one or more subdirectories.

   :param out_var: Variable to append found files to
   :type out_var: string
   :param sub_paths: One or more subdirectory paths to search within
   :type sub_paths: string or list of strings

   :post: out_var contains the list of found files appended to existing content

   .. note::
      Searches for files with extensions: .cpp, .hpp, .inl
      When multiple paths are provided, all paths are searched and results are combined.

#]]
function(cth_glob_cpp OUT_VAR)
    cth_glob(${OUT_VAR} ${ARGN} PATTERNS "*.cpp" "*.hpp" "*.inl" "*.h" "*.cu" "*.cuh")
    set(${OUT_VAR} ${${OUT_VAR}} PARENT_SCOPE)
endfunction()

#[[.rst:
.. command:: cth_glob_cppm

   .. code-block:: cmake

      cth_glob_cppm(<out_var> <sub_paths...>)

   Recursively globs for C++ module interface files in one or more subdirectories.

   :param out_var: Variable to append found files to
   :type out_var: string
   :param sub_paths: One or more subdirectory paths to search within
   :type sub_paths: string or list of strings

   :post: out_var contains the list of found files appended to existing content

   .. note::
      Searches for files with extension: .cppm (C++ module interface files)
      When multiple paths are provided, all paths are searched and results are combined.

#]]
function(cth_glob_cppm OUT_VAR)
    cth_glob(${OUT_VAR} ${ARGN} PATTERNS "*.cppm")
    set(${OUT_VAR} ${${OUT_VAR}} PARENT_SCOPE)
endfunction()

#[[.rst:
.. command:: cth_add_resources

   .. code-block:: cmake

      cth_add_resources(<target_name> <resource_paths...>)

   Adds post-build commands to copy one or more resource directories to the target's output directory.

   :param target_name: Name of the target to add resources to
   :type target_name: string
   :param resource_paths: One or more paths to resource directories to copy
   :type resource_paths: string or list of strings

   :pre: target_name exists
   :post: Resources are copied to the target directory after build, preserving directory structure

   .. note::
      Each resource directory will be copied to ``$<TARGET_FILE_DIR:target>/<resource_path>``.
      Directory structure is preserved relative to the original resource_path.
      When multiple paths are provided, each directory is copied separately.

#]]
function(cth_add_resources TARGET_NAME)
    cth_assert_target("${TARGET_NAME}")

    set(RESOURCE_PATHS ${ARGN})

    foreach(RESOURCE_PATH IN LISTS RESOURCE_PATHS)
        # Get the absolute path to the source resources
        get_filename_component(ABS_RESOURCE_PATH ${RESOURCE_PATH} ABSOLUTE)

        add_custom_command(
            TARGET ${TARGET_NAME}
            POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${ABS_RESOURCE_PATH}"

            # Use the original RESOURCE_PATH to preserve the structure
            "$<TARGET_FILE_DIR:${TARGET_NAME}>/${RESOURCE_PATH}"
            COMMENT "Copying resource directory: ${RESOURCE_PATH}"
            VERBATIM
        )
    endforeach()
endfunction()

#[[.rst:
.. command:: cth_target_enable_sanitizers

   .. code-block:: cmake

      cth_target_enable_sanitizers(<target> [CONFIGS <configs...>] [SANITIZERS <sanitizers...>])

   Enables sanitizers for the specified target and build configurations.

   :param target: Name of the target to enable sanitizers for
   :type target: string
   :param CONFIGS: List of build configurations to enable sanitizers for (e.g., Debug, Release)
   :type CONFIGS: list of strings
   :param SANITIZERS: List of sanitizers to enable
   :type SANITIZERS: list of strings

   :pre: target exists
   :pre: SANITIZERS list is not empty
   :pre: CONFIGS list is not empty
   :post: Sanitizers are enabled for the target in specified configurations

   .. note::
      **Supported sanitizers:**

      - ``address`` - AddressSanitizer (ASan): detects memory errors
      - ``undefined`` - UndefinedBehaviorSanitizer (UBSan): detects undefined behavior

   .. warning::
      **MSVC limitations:**

      - UndefinedBehaviorSanitizer (``undefined``) is NOT supported on MSVC and will be skipped with a warning
      - Only AddressSanitizer (``address``) is available on MSVC

   .. warning::
      Unsupported sanitizer names will cause a FATAL_ERROR.

#]]
function(cth_target_enable_sanitizers target)
    # 1. Validate Target
    cth_assert_target("${target}")

    # 2. Parse Arguments
    set(multiValueArgs CONFIGS SANITIZERS)
    cmake_parse_arguments(PARSE_ARGV 1 ARG "" "" "${multiValueArgs}")

    # 3. Validate Parsing & Requirements via Assertions
    cth_assert_empty("${ARG_UNPARSED_ARGUMENTS}")

    cth_assert_not_empty("${ARG_SANITIZERS}")
    cth_assert_not_empty("${ARG_CONFIGS}")

    # 4. Prepare Generator Expressions
    string(REPLACE ";" "," CONFIG_CSV "${ARG_CONFIGS}")
    set(GENEX_CONDITION "$<CONFIG:${CONFIG_CSV}>")

    # 5. Iterate and Apply
    foreach(sanitizer IN LISTS ARG_SANITIZERS)
        if(sanitizer STREQUAL "address")
            target_compile_options(${target} PRIVATE
                "$<${GENEX_CONDITION}:$<$<CXX_COMPILER_ID:MSVC>:/fsanitize=address>$<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-fsanitize=address>>"
            )
            target_link_options(${target} PRIVATE
                "$<${GENEX_CONDITION}:$<$<CXX_COMPILER_ID:MSVC>:/fsanitize=address>$<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-fsanitize=address>>"
            )

        elseif(sanitizer STREQUAL "undefined")
            if(CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
                message(WARNING "cth_target_enable_sanitizers: MSVC does not support UBSan. Skipping for target '${target}'.")
            else()
                target_compile_options(${target} PRIVATE "$<${GENEX_CONDITION}:-fsanitize=undefined>")
                target_link_options(${target} PRIVATE "$<${GENEX_CONDITION}:-fsanitize=undefined>")
            endif()

        else()
            message(FATAL_ERROR "ERROR cth_target_enable_sanitizers: Unsupported sanitizer '${sanitizer}' [args: ${ARGV}]")
        endif()
    endforeach()
endfunction()

#[[.rst:
.. command:: cth_target_enable_build_cache

   .. code-block:: cmake

      cth_target_enable_build_cache(<target> [OPTIONAL])

   Enables build caching for the specified target using BuildCache.

   :param target: Name of the target to enable build caching for
   :type target: string

   :pre: target exists
   :pre: buildcache program is found in PATH
   :post: C and C++ compiler launchers are set to buildcache for the target if found

   .. note::
      BuildCache must be installed and available in PATH.

   .. warning::
      Sets the debug info format to `embedded` for msvc if buildcache is enabled
            
   .. seealso::
      Use ``cth_enable_build_cache()`` from cth_tool_utilities to enable globally.

#]]
function(cth_target_enable_build_cache target)
    cth_assert_target("${target}")

    cmake_parse_arguments(PARSE_ARGV 1 ARG "OPTIONAL" "" "")

    include(cth_tool_utilities)

    if(ARG_OPTIONAL)
        cth_find_program(BUILDCACHE_PROGRAM buildcache OPTIONAL)
    else()
        cth_find_program(BUILDCACHE_PROGRAM buildcache)
    endif()

    if(NOT BUILDCACHE_PROGRAM)
        message(STATUS "Couldn't enable BuildCache for target '${target}'")
        return()
    endif()

    message(STATUS "BuildCache enabled for target '${target}'")

    set(CMAKE_MSVC_DEBUG_INFORMATION_FORMAT "$<$<CONFIG:Debug,RelWithDebInfo>:Embedded>" PARENT_SCOPE)

    set_target_properties(
        ${target} PROPERTIES
        C_COMPILER_LAUNCHER "${BUILDCACHE_PROGRAM}"
        CXX_COMPILER_LAUNCHER "${BUILDCACHE_PROGRAM}"
    )
endfunction()

#[[.rst:
.. command:: cth_target_add_modules

   .. code-block:: cmake

      cth_target_add_modules(<target_name> [PUBLIC <files...>] [PRIVATE <files...>])

   Adds C++ module files to a target with specified visibility.

   :param target_name: Name of the target to add modules to
   :type target_name: string
   :param PUBLIC: List of public module files (.cppm)
   :type PUBLIC: list of file paths
   :param PRIVATE: List of private module files (.cppm)
   :type PRIVATE: list of file paths

   :pre: target_name exists
   :pre: target_name is NOT an INTERFACE library (C++ modules not supported)
   :pre: At least one of PUBLIC or PRIVATE arguments is provided
   :post: Module files are added to target with appropriate file sets and CXX_SCAN_FOR_MODULES is enabled

   .. note::
      **Public modules:**

      - Added to ``CXX_MODULES`` file set
      - Visible to consumers of the target

      **Private modules:**

      - Added to ``<target_name>_private_modules`` file set
      - Only visible within the target itself

   .. warning::
      INTERFACE libraries do NOT support C++ modules and will cause a FATAL_ERROR.

#]]
function(cth_target_add_modules TARGET_NAME)
    # 1. Basic existence check
    cth_assert_target("${TARGET_NAME}")

    # 2. Interface check (C++ Modules cannot be added to INTERFACE libraries)
    get_target_property(TGT_TYPE ${TARGET_NAME} TYPE)
    cth_assert_false(
        "${TGT_TYPE}" STREQUAL "INTERFACE_LIBRARY"
        REASON "'${TARGET_NAME}' is an INTERFACE library which do NOT support modules"
    )

    set(options "")
    set(oneValueArgs "")
    set(multiValueArgs PUBLIC PRIVATE)
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    cth_assert_empty(
        "${ARGS_UNPARSED_ARGUMENTS}"
        REASON "Unparsed arguments found: '${ARGS_UNPARSED_ARGUMENTS}'. All modules must be specified with PUBLIC or PRIVATE keywords."
    )

    # 3. Enable modules & scanning
    set_target_properties(
        ${TARGET_NAME} PROPERTIES
        CXX_SCAN_FOR_MODULES ON
    )

    # 4. Private Modules
    if(ARGS_PRIVATE)
        target_sources(${TARGET_NAME} PRIVATE
            FILE_SET "${TARGET_NAME}_private_modules" TYPE CXX_MODULES FILES ${ARGS_PRIVATE}
        )
    endif()

    # 5. Public Modules
    if(ARGS_PUBLIC)
        target_sources(${TARGET_NAME} PUBLIC
            FILE_SET CXX_MODULES TYPE CXX_MODULES FILES ${ARGS_PUBLIC}
        )
    endif()
endfunction()

#[[.rst:
.. command:: cth_add_clang_format_target

   .. code-block:: cmake

      cth_add_clang_format_target(<target_name> [OPTIONAL] <files...>)

   Creates a custom target that runs clang-format on specified files.
   If OPTIONAL is specified, does not error and skips target creation if clang-format is not found.

   :param target_name: Name of the custom target to create
   :param OPTIONAL: If specified, do not raise FATAL_ERROR if clang-format is not found
   :param files: List of source files to format

   :post: A custom target is created if found, or configuration terminates with FATAL_ERROR if not found (unless OPTIONAL)

   .. note::
      - The format target uses ``-i`` flag to format files in-place
      - The ``-style=file`` flag means clang-format will look for a .clang-format configuration file
      - Files are formatted relative to CMAKE_SOURCE_DIR

   .. seealso::
      - ``cth_find_clang_format(OPTIONAL)`` from cth_tool_utilities to locate clang-format optionally

#]]
function(cth_add_clang_format_target TARGET_NAME)
    cmake_parse_arguments(PARSE_ARGV 1 ARG "OPTIONAL" "" "")

    # Use a different variable name to avoid conflicts with the parsed ARG_OPTIONAL boolean
    if(ARG_OPTIONAL)
        set(FIND_OPTIONAL_ARG "OPTIONAL")
    else()
        set(FIND_OPTIONAL_ARG "")
    endif()

    cth_assert_not_empty("${TARGET_NAME}" REASON "add_clang_format_target requires a target name")

    # Use ARG_UNPARSED_ARGUMENTS instead of ARGN so "OPTIONAL" isn't treated as a file
    set(FILES_TO_FORMAT ${ARG_UNPARSED_ARGUMENTS})
    cth_assert_not_empty("${FILES_TO_FORMAT}" REASON "no files provided")

    include(cth_tool_utilities)

    # Pass the safely stored string to the find function
    cth_find_clang_format(${FIND_OPTIONAL_ARG})

    if(NOT CLANG_FORMAT_EXECUTABLE)
        return()
    endif()

    set(FILE_LIST_PATH "${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}_files.txt")
    string(REPLACE ";" "\n" FILES_TO_FORMAT_STR "${FILES_TO_FORMAT}")
    file(WRITE "${FILE_LIST_PATH}" "${FILES_TO_FORMAT_STR}\n")

    add_custom_target(
        ${TARGET_NAME}
        COMMAND ${CLANG_FORMAT_EXECUTABLE} -i -style=file --files=${FILE_LIST_PATH}
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        COMMENT "Formatting all source files with clang-format..."
        VERBATIM
    )
endfunction()

#[[.rst:
.. command:: cth_add_uncrustify_target

   .. code-block:: cmake

      cth_add_uncrustify_target(<target_name> [OPTIONAL] <files...>)

   Creates a custom target that runs uncrustify on specified files.
   If OPTIONAL is specified, does not error and skips target creation if uncrustify is not found.

   :param target_name: Name of the custom target to create
   :param OPTIONAL: If specified, do not raise FATAL_ERROR if uncrustify is not found
   :param files: List of source files to format

   :pre expects uncrustify.cfg in root directory
   :post: A custom target is created if found, or configuration terminates with FATAL_ERROR if not found (unless OPTIONAL)

   .. note::
      - The format target uses ``--replace`` and ``--no-backup`` flags to format files in-place
      - The ``-F`` flag is used to pass the text file containing the list of files to format
      - Files are formatted relative to CMAKE_SOURCE_DIR
      - Uncrustify will look for an uncrustify.cfg file in the working directory or rely on the UNCRUSTIFY_CONFIG environment variable.

   .. seealso::
      - ``cth_find_uncrustify(OPTIONAL)`` from cth_tool_utilities to locate uncrustify optionally

#]]
function(cth_add_uncrustify_target TARGET_NAME)
    cmake_parse_arguments(PARSE_ARGV 1 ARG "OPTIONAL" "" "")

    # Use a different variable name to avoid being overwritten by cmake_parse_arguments
    if(ARG_OPTIONAL)
        set(FIND_OPTIONAL_ARG "OPTIONAL")
    else()
        set(FIND_OPTIONAL_ARG "")
    endif()

    cth_assert_not_empty("${TARGET_NAME}" REASON "add_uncrustify_target requires a target name")

    set(FILES_TO_FORMAT ${ARG_UNPARSED_ARGUMENTS})
    cth_assert_not_empty("${FILES_TO_FORMAT}" REASON "no files provided")

    include(cth_tool_utilities)

    cth_find_uncrustify(${FIND_OPTIONAL_ARG})

    if(NOT UNCRUSTIFY_EXECUTABLE)
        return()
    endif()

    set(FILE_LIST_PATH "${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}_files.txt")
    string(REPLACE ";" "\n" FILES_TO_FORMAT_STR "${FILES_TO_FORMAT}")
    file(WRITE "${FILE_LIST_PATH}" "${FILES_TO_FORMAT_STR}\n")

    add_custom_target(
        ${TARGET_NAME}
        COMMAND ${UNCRUSTIFY_EXECUTABLE} --replace --no-backup -c uncrustify.cfg -q -F ${FILE_LIST_PATH}
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        COMMENT "Formatting all source files with uncrustify..."
        VERBATIM
    )
endfunction()

#[[.rst:
.. command:: cth_target_attach_link_dependency

   .. code-block:: cmake

      cth_target_attach_link_dependency(<target> <files...>)

   Attaches external shared libraries to a target by creating imported targets that are linked
   like regular libraries (on Windows, the import lib next to the DLL is used).

   :param target: The target to attach dependencies to.
   :type target: string
   :param files: List of shared library paths to attach.
   :type files: list of strings

   :pre: ``target`` must exist.

   .. note::
      Creates one internal imported target per file, deduplicated by absolute path.
      For runtime-only files that must merely ship next to consuming executables (no linking),
      use ``cth_target_attach_copy_dependency`` instead.
#]]
function(cth_target_attach_link_dependency target)
    cth_assert_target(${target})

    # IMPORTED targets have no private/compiled component of their own -- CMake only allows the
    # INTERFACE keyword of target_link_libraries() for them (PUBLIC/PRIVATE hard-error). Everything
    # attached here ends up in INTERFACE_LINK_LIBRARIES either way, so this just picks the keyword
    # CMake will actually accept for the given target.
    get_target_property(_cth_target_is_imported ${target} IMPORTED)
    if(_cth_target_is_imported)
        set(_cth_link_scope INTERFACE)
    else()
        set(_cth_link_scope PRIVATE)
    endif()

    foreach(file_path ${ARGN})
        # Resolve full path immediately
        get_filename_component(abs_path "${file_path}" ABSOLUTE)
        get_filename_component(file_name "${file_path}" NAME)

        # Generate unique target name
        string(MD5 path_hash "${abs_path}")
        set(leaf_target_name "_${target}_LINK_${path_hash}")

        if(NOT TARGET ${leaf_target_name})
            add_library(${leaf_target_name} SHARED IMPORTED GLOBAL)
            set_target_properties(${leaf_target_name} PROPERTIES
                IMPORTED_LOCATION "${abs_path}"
            )

            if(WIN32)
                # Windows links against the import library next to the DLL.
                get_filename_component(dir_name "${abs_path}" DIRECTORY)
                get_filename_component(name_we "${abs_path}" NAME_WE)

                # Construct path: dir / [prefix]filename[suffix]
                set(implib_path "${dir_name}/${CMAKE_IMPORT_LIBRARY_PREFIX}${name_we}${CMAKE_IMPORT_LIBRARY_SUFFIX}")

                if(EXISTS "${implib_path}")
                    set_target_properties(${leaf_target_name} PROPERTIES
                        IMPORTED_IMPLIB "${implib_path}"
                    )
                else()
                    message(WARNING "cth_target_attach_link_dependency: import lib for ${file_name} not found at: ${implib_path}")
                endif()
            endif()
        endif()

        # Link the imported target to the main target
        target_link_libraries(${target} ${_cth_link_scope} ${leaf_target_name})
    endforeach()
endfunction()

#[[.rst:
.. command:: cth_target_attach_copy_dependency

   .. code-block:: cmake

      cth_target_attach_copy_dependency(<target> <items...>)

   Registers files that must be copied next to any executable consuming ``target`` (directly or
   transitively), preserving their relative directory structure. Unlike
   ``cth_target_attach_link_dependency``, this does NOT create imported link targets -- it only records

   :param target: The target to attach copy dependencies to. May be an ``INTERFACE`` library.
   :type target: string
   :param items: List of items, either ``"<abs_path>|<rel_path>"`` pairs (as produced by
                 ``cth_glob(... PRESERVE_SUBPATHS)``) or bare absolute file paths.
   :type items: list of strings

   :pre: ``target`` must exist.
   :post: ``target``'s ``INTERFACE_CTH_COPY_DEPENDENCIES`` property contains one
          ``"<abs_path>|<rel_path>"`` entry per item.
   :post: ``target``'s ``TRANSITIVE_LINK_PROPERTIES`` property contains ``CTH_COPY_DEPENDENCIES``.

   .. note::
      For bare absolute paths, ``rel_path`` is just the filename -- the file lands flat next to
      the consuming target. Use ``cth_glob(... PRESERVE_SUBPATHS)`` items to preserve nested
      directory structure instead.

   .. note::
      Consumers resolve the full, deduplication-free set via
      ``$<TARGET_PROPERTY:consumer,CTH_COPY_DEPENDENCIES>``, which -- thanks to
      ``TRANSITIVE_LINK_PROPERTIES`` (CMake >= 3.30) -- evaluates as the union of
      ``INTERFACE_CTH_COPY_DEPENDENCIES`` over the consumer's entire transitive link closure. See
      ``cth_target_copy_dependencies``, which is what actually copies these files.

   .. seealso::
      - ``cth_glob(... PRESERVE_SUBPATHS)`` to produce ``"<abs_path>|<rel_path>"`` items.
      - ``cth_target_copy_dependencies`` to resolve and copy the registered items.
#]]
function(cth_target_attach_copy_dependency target)
    cth_assert_target("${target}")

    set(_cth_entries "")

    foreach(item IN LISTS ARGN)
        if(item MATCHES "^(.*)\\|(.*)$")
            set(_abs "${CMAKE_MATCH_1}")
            set(_rel "${CMAKE_MATCH_2}")
        else()
            set(_abs "${item}")
            get_filename_component(_rel "${item}" NAME)
        endif()

        get_filename_component(_abs "${_abs}" ABSOLUTE)
        list(APPEND _cth_entries "${_abs}|${_rel}")
    endforeach()

    if(_cth_entries)
        set_property(TARGET ${target} APPEND PROPERTY INTERFACE_CTH_COPY_DEPENDENCIES ${_cth_entries})
    endif()

    # Only declare CTH_COPY_DEPENDENCIES as transitive once -- APPEND doesn't dedupe, and repeated
    # entries here are harmless but pointless.
    get_target_property(_cth_transitive_props ${target} TRANSITIVE_LINK_PROPERTIES)
    if(NOT _cth_transitive_props)
        set(_cth_transitive_props "")
    endif()

    if(NOT "CTH_COPY_DEPENDENCIES" IN_LIST _cth_transitive_props)
        set_property(TARGET ${target} APPEND PROPERTY TRANSITIVE_LINK_PROPERTIES CTH_COPY_DEPENDENCIES)
    endif()
endfunction()

#[[.rst:
.. command:: cth_target_copy_dependencies

   .. code-block:: cmake

      cth_target_copy_dependencies(<target>)

   Adds a post-build step to copy runtime dependencies to the target's output directory:

   - Runtime DLLs via the ``$<TARGET_RUNTIME_DLLS:...>`` generator expression -- copied flat.
   - Items registered via ``cth_target_attach_copy_dependency`` anywhere in ``target``'s link
     closure, resolved through ``$<TARGET_PROPERTY:target,CTH_COPY_DEPENDENCIES>`` -- each copied
     to ``$<TARGET_FILE_DIR:target>/<rel_path>``, preserving the relative structure it was
     registered with (destination subdirectories are created as needed).

   :param target: The target to copy dependencies for.
   :type target: string

   :pre: ``target`` must exist.
   :pre: ``target`` must be an ``EXECUTABLE`` or ``SHARED_LIBRARY``.
   :post: Runtime DLLs are copied to ``$<TARGET_FILE_DIR:target>`` after build.
   :post: Items registered via ``cth_target_attach_copy_dependency`` on any target in ``target``'s
          link closure are copied to ``$<TARGET_FILE_DIR:target>/<rel_path>`` after build.

   .. seealso::
      - ``cth_target_attach_copy_dependency`` to register structure-preserving copy dependencies.
#]]
function(cth_target_copy_dependencies target)
    cth_assert_target("${target}")

    get_target_property(TGT_TYPE ${target} TYPE)
    cth_assert_true("${TGT_TYPE}" MATCHES "^(EXECUTABLE|SHARED_LIBRARY)$"
        REASON "cth_target_copy_dependencies: Target '${target}' is of type '${TGT_TYPE}'. This function only supports EXECUTABLES or SHARED_LIBRARIES."
    )

    get_target_property(_registered ${target} _CTH_COPY_DEPS_REGISTERED)

    if(_registered)
        message(WARNING "cth_target_copy_dependencies(${target}) called multiple times!")
        return()
    endif()

    set_property(TARGET ${target} PROPERTY _CTH_COPY_DEPS_REGISTERED TRUE)

    set(RETRY_SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/${target}_copy_retry_$<CONFIG>.cmake")

    # Generate the script. We use file(GENERATE) so generator expressions resolve correctly.
    file(GENERATE OUTPUT "${RETRY_SCRIPT}" CONTENT "
        cmake_minimum_required(VERSION 3.21)

        # Generic retry helper: runs one COMMAND up to 5 times (1s apart), FATAL_ERROR if it never
        # succeeds. Reused below for both the flat DLL copy and the per-item CTH_COPY_DEPENDENCIES
        # copies -- 'copy_if_different' is idempotent, so a partially-failed attempt just means the
        # next retry only redoes the files that didn't land.
        function(_cth_copy_retry label)
            foreach(i RANGE 1 5)
                execute_process(
                    COMMAND \${ARGN}
                    RESULT_VARIABLE CMD_RESULT
                    ERROR_VARIABLE CMD_ERR
                    OUTPUT_VARIABLE CMD_OUT
                )

                if(CMD_RESULT EQUAL 0)
                    return()
                endif()

                if(\${i} LESS 5)
                    # Print a warning but don't fail yet
                    message(STATUS \"[\${label}] Copy failed (Attempt \${i}/5). Retrying in 1s...\")

                    # sleep
                    execute_process(COMMAND \${CMAKE_COMMAND} -E sleep 1)
                else()
                    # Final attempt failed, print error and exit with failure code
                    message(STATUS \"\${CMD_OUT}\")
                    message(STATUS \"\${CMD_ERR}\")
                    message(FATAL_ERROR \"[\${label}] Failed to copy dependencies after 5 attempts.\")
                endif()
            endforeach()
        endfunction()

        set(DLLS \"$<TARGET_RUNTIME_DLLS:${target}>\")
        set(DEST \"$<TARGET_FILE_DIR:${target}>\")

        # 1. Runtime DLLs -- flat copy next to the target.
        if(DLLS)
            _cth_copy_retry(\"${target}\" \${CMAKE_COMMAND} -E copy_if_different \${DLLS} \${DEST})
        endif()

        # 2. CTH_COPY_DEPENDENCIES -- items registered via cth_target_attach_copy_dependency() on
        #    any target in this target's link closure (resolved here via TRANSITIVE_LINK_PROPERTIES,
        #    which is why this works even if the attaching subdirectory is processed after this
        #    one -- resolution happens at generate time, not configure time). Each entry is
        #    \"<abs_path>|<rel_path>\"; rel_path (filename included) is preserved under DEST so
        #    nested directory structure survives the copy.
        set(COPY_DEPS \"$<TARGET_PROPERTY:${target},CTH_COPY_DEPENDENCIES>\")

        foreach(_entry IN LISTS COPY_DEPS)
            if(NOT _entry)
                continue()
            endif()

            string(FIND \"\${_entry}\" \"|\" _sep_idx)
            if(_sep_idx EQUAL -1)
                message(FATAL_ERROR \"[${target}] Malformed CTH_COPY_DEPENDENCIES entry (missing '|'): \${_entry}\")
            endif()

            string(SUBSTRING \"\${_entry}\" 0 \${_sep_idx} _abs)
            math(EXPR _rel_start \"\${_sep_idx} + 1\")
            string(SUBSTRING \"\${_entry}\" \${_rel_start} -1 _rel)

            set(_dest_file \"\${DEST}/\${_rel}\")
            get_filename_component(_dest_dir \"\${_dest_file}\" DIRECTORY)

            file(MAKE_DIRECTORY \"\${_dest_dir}\")
            _cth_copy_retry(\"${target}\" \${CMAKE_COMMAND} -E copy_if_different \${_abs} \${_dest_file})
        endforeach()
    ")

    # Add the post-build step to run the generated script
    add_custom_command(TARGET ${target} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -P "${RETRY_SCRIPT}"
        COMMENT "Propagating runtime dependencies for ${target} ..."
    )
endfunction()

#[[.rst:
.. command:: cth_target_set_constexpr_steps

   .. code-block:: cmake

      cth_target_set_constexpr_steps(<target> <number>)

   Sets the number as constexpr steps for MSVC, CLANG and GCC

   :param target: The target to copy dependencies for.
   :type target: string

   :param number: number of constexpr steps
   :type target: integer

   :pre: ``target`` must exist.
   :pre: ``number`` must not be empty.
   :post: max constexpr steps set for the target
#]]
function(cth_target_set_constexpr_steps target number)
    cth_assert_target(${target})
    cth_assert_integer(${number} REASON "constexpr steps must be an integer")

    # 1. Choose the correct flag for Clang / clang-cl
    if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        # If the frontend is MSVC (clang-cl), we must use the /clang: prefix
        if(CMAKE_CXX_COMPILER_FRONTEND_VARIANT STREQUAL "MSVC" OR(WIN32 AND MSVC))
            set(CLANG_CONSTEXPR_FLAG "/clang:-fconstexpr-steps=${number}")
        else()
            # Standard Clang (0 = unlimited steps)
            set(CLANG_CONSTEXPR_FLAG "-fconstexpr-steps=${number}")
        endif()
    endif()

    # 2. Apply the flags to the target
    target_compile_options(${target} PRIVATE
        $<$<CXX_COMPILER_ID:Clang>:${CLANG_CONSTEXPR_FLAG}>
        $<$<CXX_COMPILER_ID:GNU>:-fconstexpr-ops-limit=${number}>
        $<$<CXX_COMPILER_ID:MSVC>:/constexpr:steps${number}>
    )
endfunction(cth_target_set_constexpr_steps target number)