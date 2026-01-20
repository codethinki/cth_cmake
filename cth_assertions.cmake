cmake_minimum_required(VERSION 4.1)

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

.. command:: cth_assert_if

   .. code-block:: cmake

      cth_assert_if(<reason> <condition...>)

   Asserts that a boolean condition evaluates to TRUE, terminating configuration otherwise.

   :param reason: Error message to display if the condition is FALSE
   :type reason: string
   :param condition: CMake boolean expression to evaluate
   :type condition: boolean expression

   :pre: condition is a valid CMake boolean expression
   :post: condition evaluates to TRUE, or configuration terminates with FATAL_ERROR

macro(cth_assert_if reason)
    if(NOT ${ARGN})
        _cth_assertion_failure("${reason}")
    endif()
endmacro()

.. command:: cth_assert_if_not

   .. code-block:: cmake

      cth_assert_if_not(<reason> <condition...>)

   Asserts that a boolean condition evaluates to FALSE, terminating configuration otherwise.

   :param reason: Error message to display if the condition is TRUE
   :type reason: string
   :param condition: CMake boolean expression to evaluate
   :type condition: boolean expression

   :pre: condition is a valid CMake boolean expression
   :post: condition evaluates to FALSE, or configuration terminates with FATAL_ERROR

macro(cth_assert_if_not reason)
    if(${ARGN})
        _cth_assertion_failure("${reason}")
    endif()
endmacro()

.. command:: cth_assert_not_cmd

   .. code-block:: cmake

      cth_assert_not_cmd(<cmd>)

   Asserts that a CMake command, function, or macro is NOT defined.

   :param cmd: Name of the command to check
   :type cmd: string

   :post: cmd is NOT a defined command/function/macro, or configuration terminates with FATAL_ERROR

function(cth_assert_not_cmd cmd)
    cth_assert_if_not("Command '${cmd}' already defined" COMMAND ${cmd})
endfunction()

.. command:: cth_assert_cmd

   .. code-block:: cmake

      cth_assert_cmd(<cmd>)

   Asserts that a CMake command, function, or macro is defined.

   :param cmd: Name of the command to check
   :type cmd: string

   :post: cmd is a defined command/function/macro, or configuration terminates with FATAL_ERROR

function(cth_assert_cmd cmd)
    cth_assert_if("Command '${cmd}' not defined" COMMAND ${cmd})
endfunction()

.. command:: cth_assert_target

   .. code-block:: cmake

      cth_assert_target(<target>)

   Asserts that a CMake target exists in the current scope.

   :param target: Name of the target to check
   :type target: string

   :post: target exists, or configuration terminates with FATAL_ERROR

function(cth_assert_target target)
    cth_assert_if("Target '${target}' does not exist" TARGET ${target})
endfunction()

.. command:: cth_assert_not_target

   .. code-block:: cmake

      cth_assert_not_target(<target>)

   Asserts that a CMake target does NOT exist in the current scope.

   :param target: Name of the target to check
   :type target: string

   :post: target does NOT exist, or configuration terminates with FATAL_ERROR

function(cth_assert_not_target target)
    cth_assert_if_not("Target '${target}' already exists" TARGET ${target})
endfunction()

.. command:: cth_assert_empty

   .. code-block:: cmake

      cth_assert_empty(<value>)

   Asserts that a value is an empty string.

   :param value: Value to check for emptiness
   :type value: string

   :post: value is an empty string, or configuration terminates with FATAL_ERROR

function(cth_assert_empty value)
    if(NOT ("${value}" STREQUAL ""))
        _cth_assertion_failure("Value not empty: '${value}'")
    endif()
endfunction()

.. command:: cth_assert_not_empty

   .. code-block:: cmake

      cth_assert_not_empty(<value>)

   Asserts that a value is NOT an empty string.

   :param value: Value to check for non-emptiness
   :type value: string

   :post: value is NOT an empty string, or configuration terminates with FATAL_ERROR

function(cth_assert_not_empty value)
    if("${value}" STREQUAL "")
        _cth_assertion_failure("Value is empty")
    endif()
endfunction()

.. command:: cth_assert_program

   .. code-block:: cmake

      cth_assert_program(<prog> [args...])

   Locates an external program and exports its path to the parent scope.

   :param prog: Name of the program to find
   :type prog: string
   :param args: Additional arguments to pass to find_program (e.g., PATHS, HINTS)
   :type args: optional arguments

   :post: <PROG>_PROGRAM variable is set in PARENT_SCOPE with the full path to the program, or configuration terminates with FATAL_ERROR if not found

   .. note::
      The output variable name is the uppercase version of prog with "_PROGRAM" appended.
      For example, ``cth_assert_program(git)`` sets ``GIT_PROGRAM``.

function(cth_assert_program prog)
    string(TOUPPER "${prog}" PROG_UPPER)
    set(VAR_NAME "${PROG_UPPER}_PROGRAM")
    
    find_program(${VAR_NAME} "${prog}" ${ARGN})
    
    cth_assert_if("Program '${prog}' not found" ${VAR_NAME})
    
    set(${VAR_NAME} "${${VAR_NAME}}" PARENT_SCOPE)
endfunction()