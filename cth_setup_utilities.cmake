.. command:: cth_set_compiler_specifics

   .. code-block:: cmake

      cth_set_compiler_specifics()

   Applies compiler-specific common flags for the project.

   :post: Compiler flags are set based on detected compiler

   .. note::
      **MSVC:**

      - Adds ``/utf-8`` flag for UTF-8 source and execution character sets

      **Other compilers (GCC, Clang):**

      - Adds ``-fexceptions`` flag to enable exception handling

function(cth_set_compiler_specifics)
message("Using compiler ${CMAKE_CXX_COMPILER}")

if(MSVC)
	add_compile_options(/utf-8)
else()
	add_compile_options(-fexceptions)
endif()
endfunction()



.. command:: cth_set_newest_c_cpp_standard

   .. code-block:: cmake

      cth_set_newest_c_cpp_standard()

   Sets the project to use the newest supported C/C++ standard.

   :post: CMAKE_CXX_STANDARD and CMAKE_C_STANDARD are set to newest supported version
   :post: CMAKE_CXX_STANDARD_REQUIRED is set to ON

   .. note::
      **MSVC:**

      - Sets C++ standard to C++23
      - Adds ``/std:c++latest`` flag for bleeding-edge features

      **Other compilers (GCC, Clang):**

      - Sets C++ standard to C++26 (experimental)

   .. note::
      C standard is set to match the C++ standard version.

   .. warning::
      This is a macro, not a function. Variables are set in the calling scope.

macro(cth_set_newest_c_cpp_standard)
if(MSVC)
	set(CMAKE_CXX_STANDARD 23)
	add_compile_options(/std:c++latest)
else()
	set(CMAKE_CXX_STANDARD 26)
endif()

set(CMAKE_C_STANDARD ${CMAKE_CXX_STANDARD})

set(CMAKE_CXX_STANDARD_REQUIRED ON)

message("Set cxx standard to ${CMAKE_CXX_STANDARD}")
endmacro()