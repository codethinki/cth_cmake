function(glob_cpp OUT_VAR SUB_PATH)
    file(GLOB_RECURSE FOUND_FILES
        CONFIGURE_DEPENDS
        "${SUB_PATH}/*.cpp"
        "${SUB_PATH}/*.hpp"
        "${SUB_PATH}/*.inl"
    )

    set(${OUT_VAR} ${${OUT_VAR}} ${FOUND_FILES} PARENT_SCOPE)
endfunction()


function(glob_cppm OUT_VAR SUB_PATH)
    file(GLOB_RECURSE FOUND_FILES
        CONFIGURE_DEPENDS
        "${SUB_PATH}/*.cppm"
    )

    set(${OUT_VAR} ${${OUT_VAR}} ${FOUND_FILES} PARENT_SCOPE)
endfunction()

function(add_resources TARGET_NAME RESOURCE_PATH)
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

cmake_minimum_required(VERSION 3.25)

function(target_enable_sanitizers target)
    # --- Error Definitions ---
    set(ERR_PREFIX "ERROR target_enable_sanitizers:")
    set(ERR_TARGET_MISSING "Target '${target}' does not exist")
    set(ERR_UNPARSED "Unparsed arguments found")
    set(ERR_NO_SANITIZERS "No SANITIZERS specified")
    set(ERR_NO_CONFIGS "No CONFIGS specified")
    set(ERR_BAD_SANITIZER "Unsupported sanitizer")

    # --- 1. Validate Target ---
    if(NOT TARGET "${target}")
        message(FATAL_ERROR "${ERR_PREFIX} ${ERR_TARGET_MISSING} [args: ${ARGV}]")
    endif()

    # --- 2. Parse Arguments ---
    set(multiValueArgs CONFIGS SANITIZERS)
    cmake_parse_arguments(PARSE_ARGV 1 ARG "" "" "${multiValueArgs}")

    # --- 3. Validate Parsing & Requirements ---
    if(ARG_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR "${ERR_PREFIX} ${ERR_UNPARSED}: '${ARG_UNPARSED_ARGUMENTS}' [args: ${ARGV}]")
    endif()

    if(NOT ARG_SANITIZERS)
        message(FATAL_ERROR "${ERR_PREFIX} ${ERR_NO_SANITIZERS} [args: ${ARGV}]")
    endif()

    if(NOT ARG_CONFIGS)
        message(FATAL_ERROR "${ERR_PREFIX} ${ERR_NO_CONFIGS} [args: ${ARGV}]")
    endif()

    # --- 4. Prepare Generator Expressions ---
    # Convert list "Debug;Release" to "Debug,Release" for $<CONFIG:...>
    string(REPLACE ";" "," CONFIG_CSV "${ARG_CONFIGS}")
    set(GENEX_CONDITION "$<CONFIG:${CONFIG_CSV}>")

    # --- 5. Iterate and Apply Sanitizers ---
    foreach(sanitizer IN LISTS ARG_SANITIZERS)
        if(sanitizer STREQUAL "address")
            # ASan: MSVC uses /fsanitize=address, others -fsanitize=address
            target_compile_options(${target} PRIVATE
                "$<${GENEX_CONDITION}:$<$<CXX_COMPILER_ID:MSVC>:/fsanitize=address>$<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-fsanitize=address>>"
            )
            target_link_options(${target} PRIVATE
                "$<${GENEX_CONDITION}:$<$<CXX_COMPILER_ID:MSVC>:/fsanitize=address>$<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-fsanitize=address>>"
            )

        elseif(sanitizer STREQUAL "undefined")
            # UBSan: MSVC Warning, others -fsanitize=undefined
            if(CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
                message(WARNING "target_enable_sanitizers: MSVC does not support UBSan. Skipping for target '${target}'.")
            else()
                target_compile_options(${target} PRIVATE
                    "$<${GENEX_CONDITION}:-fsanitize=undefined>"
                )
                target_link_options(${target} PRIVATE
                    "$<${GENEX_CONDITION}:-fsanitize=undefined>"
                )
            endif()

        else()
            message(FATAL_ERROR "${ERR_PREFIX} ${ERR_BAD_SANITIZER} '${sanitizer}' [args: ${ARGV}]")
        endif()
    endforeach()
endfunction()


function(target_enable_build_cache target)
    set(ERR_PREFIX "ERROR target_enable_build_cache:")
    
    if(NOT TARGET "${target}")
        message(FATAL_ERROR "${ERR_PREFIX} Target '${target}' does not exist [args: ${ARGV}]")
    endif()

    find_tool(buildcache)

    set_target_properties(${target} PROPERTIES
        C_COMPILER_LAUNCHER "${BUILDCACHE_PROGRAM}"
        CXX_COMPILER_LAUNCHER "${BUILDCACHE_PROGRAM}"
    )
endfunction()