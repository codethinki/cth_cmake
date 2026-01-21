# cth cmake
This is an opinionated cross-platform c++ cmake utility library to enable quicker and safer use of cmake. 

**VERY PRE ALPHA CURRENTLY, DONT EXPECT BACKWARDS COMPATIBILITY**

**[Quick Start](#quick-start)**


Requirements [(guide)](#dependencies--installation):
- [cmake](https://cmake.org/) 4+
- [vcpkg](https://github.com/microsoft/vcpkg)
- `VCPKG_ROOT` must be defined


<br>
<br>


# overview

## cth_assertions
Simple assertions that every language should have:
  - `cth_assert_if[_not]` — check boolean conditions and fail configuration when the condition is (not) met.
  - `cth_assert_[_not]_cmd` — verify a CMake command/function is (not) present and fail on mismatch.
  - `cth_assert_[_not]_target` — assert a CMake target does (not) exists in the current scope.
  - `cth_assert_[_not]_empty` — assert a string value is (not) empty.
  - `cth_assert_program` — locate an external program (supports `find_program` args) and export `<PROG>_PROGRAM` to the parent scope (fails if not found).

## cth_target_utilities
To help you set up targets and dependencies quicker:

  - `cth_glob` — generic recursive glob for specified file patterns/masks and append results to a variable.
  - `cth_glob_cpp` — recursive glob for common C++ source/header/file-set extensions and append results to a variable.
  - `cth_glob_cppm` — recursive glob for C++ module interface files (.cppm).
  - `cth_add_resources` — add a POST_BUILD step to copy resource directories next to a target's binary.
  - `cth_target_add_modules` — add C++ module files to a target with PUBLIC/PRIVATE visibility.
  - `cth_target_enable_sanitizers` — enable Address/Undefined sanitizers for specified targets/configurations.
  - `cth_target_enable_build_cache` — enable per-target build-cache integration ([installation](#optional))

## cth_install_utilities
**Ever wanted to create a cmake installable package?**  
Now made easy, just build the `<main-component>_package` target and you are good to go:

  - `cth_pkg_target_add_modules` — add C++ module file-sets to a target (via `cth_target_add_modules`) and register it for installation.
  - `cth_pkg_target_find_package` — wrap `find_package` and record the dependency for generated package config files.
  - `cth_pkg_target_include_directories` — configure target include directories with appropriate install interfaces.
  - `cth_create_package` — finalize export sets, generate config/version files, and create the package target.

**This has naming implications**, subcomponents should be named `<main-component>_<subcomponent>` to be installable via `<main-component>::<subcomponent>`.

This will also create additional cmake targets but dont worry about it.

## cth_setup_utilities
this is more or less for me, very handy but no backwards compatibility guaranteed

  - `cth_set_compiler_specifics` — apply compiler-specific common flags (MSVC vs others).
  - `cth_set_newest_c_cpp_standard` (macro) — prefer the newest supported C/C++ standard and set related policy/flags.


## cth_tool_utilities
  - `cth_enable_build_cache` — enable BuildCache globally by setting C/C++ compiler launcher variables. ([installation](#optional))

## toolchain.cmake
  - (toolchain configuration) — contains the project's recommended toolchain preset for CMake.

<br>
<br>

# quick start
1. **install the requirements (guide below)**
2. **add as submodule (recommended) or clone normally:**
    - add as submodule:
        - `git submodule add https://github.com/codethinki/cth_cmake.git lib/cth_cmake/`
        - `git submodule update --init --recursive`

    - or `git clone https://github.com/codethinki/cth_cmake` 
3. **add to your cmake preset**
    ```json
    //CMakePresets.txt
    {
        //...
        "configurePresets": [
                //...
                {
                    "name": "cth_cmake",
                    "hidden": true,
                    "cacheVariables": {
                                    //replace with <path_to_clone> if you dont use submodule
                        "CMAKE_TOOLCHAIN_FILE": "${sourceDir}/lib/cth_cmake/toolchain.cmake"
                    }
                },
                //...    
        ]
    }
    ```
4. **let used presets inherit from this**
    ```json
    //...
        "configurePresets": [
                //...
                {
                    "name": "<your_preset>",
                    "inherits": [
                        "cth_cmake",
                        //...
                    ]
                },
                //...
        ]
    ```

5. **enjoy :)**

# dependencies & installation
## Required (kinda)
-  [vcpkg](https://github.com/microsoft/vcpkg)
    1. install vcpkg
    2. open your repo in the terminal
    3. `vcpkg new --application` (add local manifest)
    4. add packages via: `vcpkg add port <your_package_here>`

    altho i strongly advise against it, you can disable automatic vcpkg integration with `CTH_DISABLE_VCPKG_INTEGRATION` 

## Optional
-  [BuildCache](https://gitlab.com/bits-n-bites/buildcache)  (windows guide, dunno for linux :D):
    1. install [scoop](https://scoop.sh/) (windows only)
    2. `scoop bucket add extras`
    3. `scoop install BuildCache`
