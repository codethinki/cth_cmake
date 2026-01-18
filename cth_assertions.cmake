cmake_minimum_required(VERSION 4.1)

# _cth_assertion_failure(<reason> <args...>)
# post: terminates configuration with FATAL_ERROR
macro(_cth_assertion_failure reason)
    message(FATAL_ERROR "ERROR: ${reason} [args: ${ARGN}]")
endmacro()

# cth_assert_if(<condition> <reason> <args...>)
# pre: condition is a cmake bool expression
# post: condition is TRUE
function(cth_assert_if condition reason)
    if(NOT (${condition}))
        _cth_assertion_failure("${reason}" ${ARGN})
    endif()
endfunction()

# cth_assert_if_not(<condition> <reason> <args...>)
# pre: condition is a cmake bool expression
# post: condition is FALSE
function(cth_assert_if_not condition reason)
    if(${condition})
        _cth_assertion_failure("${reason}" ${ARGN})
    endif()
endfunction()

# cth_assert_not_cmd(<cmd>)
# post: cmd is NOT a defined command/function/macro
function(cth_assert_not_cmd cmd)
    cth_assert_if_not(COMMAND ${cmd} "Command '${cmd}' already defined")
endfunction()

# cth_assert_cmd(<cmd>)
# post: cmd is a defined command/function/macro
function(cth_assert_cmd cmd)
    cth_assert_if(COMMAND ${cmd} "Command '${cmd}' not defined")
endfunction()

# cth_assert_target(<target>)
# post: target exists
function(cth_assert_target target)
    cth_assert_if(TARGET ${target} "Target '${target}' does not exist")
endfunction()

# cth_assert_not_target(<target>)
# post: target does NOT exist
function(cth_assert_not_target target)
    cth_assert_if_not(TARGET ${target} "Target '${target}' already exists")
endfunction()

# cth_assert_empty(<value>)
# post: value is an empty string
function(cth_assert_empty value)
    cth_assert_if("\"${value}\" STREQUAL \"\"" "Value not empty: '${value}'")
endfunction()

# cth_assert_not_empty(<value>)
# post: value is NOT an empty string
function(cth_assert_not_empty value)
    cth_assert_if_not("\"${value}\" STREQUAL \"\"" "Value is empty")
endfunction()

# cth_assert_program(<prog>)
# post: <PROG>_PROGRAM is set in PARENT_SCOPE
function(cth_assert_program prog)
    string(TOUPPER "${prog}" PROG_UPPER)
    set(VAR_NAME "${PROG_UPPER}_PROGRAM")
    
    find_program(${VAR_NAME} "${prog}")
    
    cth_assert_if("${VAR_NAME}" "Program '${prog}' not found")
    
    set(${VAR_NAME} "${${VAR_NAME}}" PARENT_SCOPE)
endfunction()