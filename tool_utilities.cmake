function(find_tool tool_name)
    set(ERR_PREFIX "ERROR find_tool:")
    set(ERR_NOT_FOUND "Failed to find program")

    string(TOUPPER "${tool_name}" TOOL_UPPER)
    set(VAR_NAME "${TOOL_UPPER}_PROGRAM")

    find_program(${VAR_NAME} "${tool_name}")

    if(NOT ${VAR_NAME})
        message(FATAL_ERROR "${ERR_PREFIX} ${ERR_NOT_FOUND} '${tool_name}' [args: ${ARGV}]")
    endif()
endfunction()