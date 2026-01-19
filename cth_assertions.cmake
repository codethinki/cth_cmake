cmake_minimum_required(VERSION 4.1)

# _cth_assertion_failure(<reason> <args...>)
# post: terminates configuration with FATAL_ERROR
macro(_cth_assertion_failure reason)
    

    if("${reason}" STREQUAL "")
        set(reason "unknown reason")
    endif()
    if("${ARGN}" STREQUAL "")
        set(ARG_STR "")  
    else()
        set(ARG_STR "[args: ${ARGN}]")
    endif()



    message(FATAL_ERROR "ERROR: ${reason}${ARG_STR}")
endmacro()

# cth_assert_if(<reason> <condition...>)
# pre: condition is a cmake bool expression
# post: condition is TRUE
macro(cth_assert_if reason)
    if(NOT ${ARGN})
        _cth_assertion_failure("${reason}")
    endif()
endmacro()

# cth_assert_if_not(<reason> <condition...>)
# pre: condition is a cmake bool expression
# post: condition is FALSE
macro(cth_assert_if_not reason)
    if(${ARGN})
        _cth_assertion_failure("${reason}")
    endif()
endmacro()

# cth_assert_not_cmd(<cmd>)
# post: cmd is NOT a defined command/function/macro
function(cth_assert_not_cmd cmd)
    cth_assert_if_not("Command '${cmd}' already defined" COMMAND ${cmd})
endfunction()

# cth_assert_cmd(<cmd>)
# post: cmd is a defined command/function/macro
function(cth_assert_cmd cmd)
    cth_assert_if("Command '${cmd}' not defined" COMMAND ${cmd})
endfunction()

# cth_assert_target(<target>)
# post: target exists
function(cth_assert_target target)
    cth_assert_if("Target '${target}' does not exist" TARGET ${target})
endfunction()

# cth_assert_not_target(<target>)
# post: target does NOT exist
function(cth_assert_not_target target)
    cth_assert_if_not("Target '${target}' already exists" TARGET ${target})
endfunction()

# cth_assert_empty(<value>)
# post: value is an empty string
function(cth_assert_empty value)
    if(NOT ("${value}" STREQUAL ""))
        _cth_assertion_failure("Value not empty: '${value}'")
    endif()
endfunction()

# cth_assert_not_empty(<value>)
# post: value is NOT an empty string
function(cth_assert_not_empty value)
    if("${value}" STREQUAL "")
        _cth_assertion_failure("Value is empty")
    endif()
endfunction()

# cth_assert_program(<prog> [args...])
# post: <PROG>_PROGRAM is set in PARENT_SCOPE
function(cth_assert_program prog)
    string(TOUPPER "${prog}" PROG_UPPER)
    set(VAR_NAME "${PROG_UPPER}_PROGRAM")
    
    find_program(${VAR_NAME} "${prog}" ${ARGN})
    
    cth_assert_if("Program '${prog}' not found" ${VAR_NAME})
    
    set(${VAR_NAME} "${${VAR_NAME}}" PARENT_SCOPE)
endfunction()