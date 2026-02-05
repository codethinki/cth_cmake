# Copyright (c) 2026 Lukas Thomann
# Licensed under the MIT License

cmake_minimum_required(VERSION 4.1)

#[[.rst:
.. command:: _cth_assertion_failure (internal)

   .. code-block:: cmake

      _cth_assertion_failure(<reason> <args...>)

   Internal macro to terminate configuration with a formatted error message.

   :param reason: Error message describing the failure
   :type reason: string
   :param args: Additional context to append to error message
   :type args: optional arguments

   :post: Configuration terminates with FATAL_ERROR

   .. warning::
      This is an internal function. Use the public assertion functions instead.
#]]
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

#[[.rst:
.. command:: cth_assert_true

   .. code-block:: cmake

      cth_assert_true(<condition...> REASON <reason>)

   Asserts that a boolean condition evaluates to TRUE, terminating configuration otherwise.

   :param condition: CMake boolean expression to evaluate
   :type condition: boolean expression
   :param REASON: Error message to display if the condition is FALSE
   :type REASON: string

   :pre: condition is a valid CMake boolean expression
   :post: condition evaluates to TRUE, or configuration terminates with FATAL_ERROR

#]]
function(cth_assert_true)
    set(oneValueArgs REASON)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "${oneValueArgs}" "")
    
    if(NOT ${ARG_UNPARSED_ARGUMENTS})
        _cth_assertion_failure("${ARG_REASON}")
    endif()
endfunction()

#[[.rst:
.. command:: cth_assert_false

   .. code-block:: cmake

      cth_assert_false(<condition...> REASON <reason>)

   Asserts that a boolean condition evaluates to FALSE, terminating configuration otherwise.

   :param condition: CMake boolean expression to evaluate
   :type condition: boolean expression
   :param REASON: Error message to display if the condition is TRUE
   :type REASON: string

   :pre: condition is a valid CMake boolean expression
   :post: condition evaluates to FALSE, or configuration terminates with FATAL_ERROR

#]]
function(cth_assert_false)
    set(oneValueArgs REASON)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "${oneValueArgs}" "")
    
    if(${ARG_UNPARSED_ARGUMENTS})
        _cth_assertion_failure("${ARG_REASON}")
    endif()
endfunction()

#[[.rst:
.. command:: cth_assert_not_cmd

   .. code-block:: cmake

      cth_assert_not_cmd(<cmd>)

   Asserts that a CMake command, function, or macro is NOT defined.

   :param cmd: Name of the command to check
   :type cmd: string

   :post: cmd is NOT a defined command/function/macro, or configuration terminates with FATAL_ERROR

#]]
function(cth_assert_not_cmd cmd)
    cth_assert_false(COMMAND ${cmd} REASON "Command '${cmd}' already defined")
endfunction()

#[[.rst:
.. command:: cth_assert_cmd

   .. code-block:: cmake

      cth_assert_cmd(<cmd>)

   Asserts that a CMake command, function, or macro is defined.

   :param cmd: Name of the command to check
   :type cmd: string

   :post: cmd is a defined command/function/macro, or configuration terminates with FATAL_ERROR

#]]
function(cth_assert_cmd cmd)
    cth_assert_true(COMMAND ${cmd} REASON "Command '${cmd}' not defined")
endfunction()

#[[.rst:
.. command:: cth_assert_target

   .. code-block:: cmake

      cth_assert_target(<target>)

   Asserts that a CMake target exists in the current scope.

   :param target: Name of the target to check
   :type target: string

   :post: target exists, or configuration terminates with FATAL_ERROR

#]]
function(cth_assert_target target)
    cth_assert_true(TARGET ${target} REASON "Target '${target}' does not exist")
endfunction()

#[[.rst:
.. command:: cth_assert_not_target

   .. code-block:: cmake

      cth_assert_not_target(<target>)

   Asserts that a CMake target does NOT exist in the current scope.

   :param target: Name of the target to check
   :type target: string

   :post: target does NOT exist, or configuration terminates with FATAL_ERROR

#]]
function(cth_assert_not_target target)
    cth_assert_false(TARGET ${target} REASON "Target '${target}' already exists")
endfunction()

#[[.rst:
.. command:: cth_assert_empty

   .. code-block:: cmake

      cth_assert_empty(<value>)

   Asserts that a value is an empty string.

   :param value: Value to check for emptiness
   :type value: string

   :post: value is an empty string, or configuration terminates with FATAL_ERROR

#]]
function(cth_assert_empty value)
    if(NOT ("${value}" STREQUAL ""))
        _cth_assertion_failure("Value not empty: '${value}'")
    endif()
endfunction()

#[[.rst:
.. command:: cth_assert_not_empty

   .. code-block:: cmake

      cth_assert_not_empty(<value>)

   Asserts that a value is NOT an empty string.

   :param value: Value to check for non-emptiness
   :type value: string

   :post: value is NOT an empty string, or configuration terminates with FATAL_ERROR

#]]
function(cth_assert_not_empty value)
    if("${value}" STREQUAL "")
        _cth_assertion_failure("Value is empty")
    endif()
endfunction()

#[[.rst:
.. command:: cth_assert_program

   .. code-block:: cmake

      cth_assert_program(<prog> [args...])

   Asserts an external program exists.

   :param prog: Name of the program to find
   :type prog: string
   :param args: Additional arguments to pass to find_program (e.g., PATHS, HINTS)
   :type args: optional arguments

   :post: program found or configuration terminates with FATAL_ERROR
#]]
function(cth_assert_program prog)
    find_program(TEMP "${prog}" ${ARGN})
    
    cth_assert_true(${VAR_NAME} REASON "Program '${prog}' not found")
endfunction()