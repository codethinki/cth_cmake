
# cth_glob(<out_var> <sub_path> [EXTENSIONS <extensions...>])
# globs recursively for file extensions in sub_path
# post: out_var contains the list of found files appended to existing content
function(cth_glob OUT_VAR SUB_PATH)
    set(multiValueArgs EXTENSIONS)
    cmake_parse_arguments(PARSE_ARGV 2 ARG "" "" "${multiValueArgs}")

    set(GLOB_PATTERNS "")
    foreach(EXT IN LISTS ARG_EXTENSIONS)
        list(APPEND GLOB_PATTERNS "${SUB_PATH}/*.${EXT}")
    endforeach()

    if(GLOB_PATTERNS)
        file(GLOB_RECURSE FOUND_FILES
            CONFIGURE_DEPENDS
            ${GLOB_PATTERNS}
        )
        set(${OUT_VAR} ${${OUT_VAR}} ${FOUND_FILES} PARENT_SCOPE)
    endif()
endfunction()

# cth_glob_cpp(<out_var> <sub_path>)
# globs recursively for .cpp, .hpp, .inl files in sub_path
# post: out_var contains the list of found files appended to existing content
function(cth_glob_cpp OUT_VAR SUB_PATH)
    cth_glob(${OUT_VAR} "${SUB_PATH}" EXTENSIONS cpp hpp inl)
    set(${OUT_VAR} ${${OUT_VAR}} PARENT_SCOPE)
endfunction()


# cth_glob_cppm(<out_var> <sub_path>)
# globs recursively for .cppm files in sub_path
# post: out_var contains the list of found files appended to existing content
function(cth_glob_cppm OUT_VAR SUB_PATH)
    cth_glob(${OUT_VAR} "${SUB_PATH}" EXTENSIONS cppm)
    set(${OUT_VAR} ${${OUT_VAR}} PARENT_SCOPE)
endfunction()



# cth_add_resources(<target_name> <resource_path>)
# Adds a post-build command to copy resources to the target directory
# pre: target_name exists
function(cth_add_resources TARGET_NAME RESOURCE_PATH)
    cth_assert_target("${TARGET_NAME}")

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
endfunction()



# cth_target_enable_sanitizers(<target> [CONFIGS <configs...>] [SANITIZERS <sanitizers...>])
# Enables sanitizers for the given target and configurations
# pre: target exists
# pre: SANITIZERS list is not empty
# pre: CONFIGS list is not empty
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



# cth_target_enable_build_cache(<target>)
# Enables build caching for the target using buildcache
# pre: target exists
# pre: buildcache program is found
function(cth_target_enable_build_cache target)
    cth_assert_target("${target}")

    cth_assert_program(buildcache)

    set_target_properties(${target} PROPERTIES
        C_COMPILER_LAUNCHER "${BUILDCACHE_PROGRAM}"
        CXX_COMPILER_LAUNCHER "${BUILDCACHE_PROGRAM}"
    )
endfunction()