# Copyright (c) 2026 Lukas Thomann
# Licensed under the MIT License

include(cth_target_utilities)

#[[.rst:
.. command:: cth_pkg_target_add_modules

   .. code-block:: cmake

      cth_pkg_target_add_modules(<target_name> [PUBLIC <files...>] [PRIVATE <files...>])

   Adds C++ module files to a target and registers it for installation.

   :param target_name: Name of the target to add modules to
   :type target_name: string
   :param PUBLIC: List of public module files (.cppm)
   :type PUBLIC: list of file paths
   :param PRIVATE: List of private module files (.cppm)
   :type PRIVATE: list of file paths

   :pre: target_name exists
   :pre: target_name is NOT an INTERFACE library (C++ modules not supported)
   :pre: At least one of PUBLIC or PRIVATE arguments is provided
   :post: Module files are added to target and target is registered for installation

   .. note::
      This function delegates to ``cth_target_add_modules()`` for core module handling,
      then registers the target for installation.

   .. seealso::
      Use ``cth_target_add_modules()`` from cth_target_utilities if installation is not needed.

#]]
function(cth_pkg_target_add_modules TARGET_NAME)
    # 1. Add modules to target
    cth_target_add_modules(${TARGET_NAME} ${ARGN})

    # 2. Register Target for installation logic
    get_property(INSTALLABLE_TARGETS GLOBAL PROPERTY _CTH_INSTALLABLE_TARGETS)
    if(NOT "${TARGET_NAME}" IN_LIST INSTALLABLE_TARGETS)
        list(APPEND INSTALLABLE_TARGETS ${TARGET_NAME})
        set_property(GLOBAL PROPERTY _CTH_INSTALLABLE_TARGETS "${INSTALLABLE_TARGETS}")
    endif()
endfunction()

#[[.rst:
.. command:: cth_pkg_target_find_package

   .. code-block:: cmake

      cth_pkg_target_find_package(<target_name> <find_package_args>...)

   Wraps find_package to ensure dependencies are found during build AND recorded for package config files.

   :param target_name: Name of the target that depends on the package
   :type target_name: string
   :param find_package_args: Arguments to pass to find_package (package name, version, components, etc.)
   :type find_package_args: variable arguments

   :post: Package is found via find_package and recorded for the generated Config.cmake file using find_dependency
   :post: The recorded ``find_dependency`` block is attached to ``target_name``'s package **component**
          only (see ``_cth_pkg_component_name``) -- it is emitted in the generated Config.cmake ONLY
          when a consumer actually requests (directly or transitively) that component.

   .. note::
      The first argument in find_package_args should be the package name.
      All arguments are recorded and will be passed to find_dependency() in the generated package config.

   .. note::
      If the package is not found and REQUIRED is specified, a clear error message is generated
      indicating which component depends on the missing package.

#]]
function(cth_pkg_target_find_package TARGET_NAME)
    # 1. Standard find_package for the current build
    find_package(${ARGN})

    # 2. Record for installation
    list(GET ARGN 0 PKG_NAME)

    # Create a safe argument list for checking existence (remove REQUIRED)
    # This ensures find_package(... QUIET) doesn't fatal-error if the package is missing,
    # allowing us to print our custom message.
    set(ARGS_CHECK_LIST ${ARGN})
    list(REMOVE_ITEM ARGS_CHECK_LIST "REQUIRED")

    list(JOIN ARGS_CHECK_LIST " " ARGS_CHECK_STR)

    # The full arguments for the actual dependency enforcement (includes REQUIRED)
    list(JOIN ARGN " " ARGS_STR)

    # We create a check block that runs find_package QUIETly first (without REQUIRED).
    # block(SCOPE_FOR VARIABLES) ensures CMAKE_MESSAGE_LOG_LEVEL changes don't leak out.
    set(CHECK_BLOCK "
block(SCOPE_FOR VARIABLES)
    set(CMAKE_MESSAGE_LOG_LEVEL ERROR)
    find_package(${ARGS_CHECK_STR} QUIET)
    if(NOT ${PKG_NAME}_FOUND)
        set(MSG \"${CMAKE_FIND_PACKAGE_NAME} component '${TARGET_NAME}' dependency missing: find_package(${ARGS_STR}) failed\")
        message(FATAL_ERROR \"\${MSG}\")
    endif()
endblock()
find_dependency(${ARGS_STR})
")
    # Recorded per TARGET_NAME so _cth_setup_package() emit each dependency only for its corresponding component.
    set_property(GLOBAL APPEND_STRING PROPERTY _CTH_PKG_DEPENDENCIES_${TARGET_NAME} "${CHECK_BLOCK}\n")
endfunction()

#[[.rst:
.. command:: cth_pkg_target_include_directories

   .. code-block:: cmake

      cth_pkg_target_include_directories(<target_name>
                                         [PUBLIC <dirs...>]
                                         [PRIVATE <dirs...>]
                                         [INTERFACE <dirs...>])

   Configures target include directories with appropriate build and install interfaces.

   :param target_name: Name of the target to configure
   :type target_name: string
   :param PUBLIC: List of public include directories
   :type PUBLIC: list of directory paths
   :param PRIVATE: List of private include directories
   :type PRIVATE: list of directory paths
   :param INTERFACE: List of interface include directories
   :type INTERFACE: list of directory paths

   :pre: target_name exists
   :post: Include directories are configured with BUILD_INTERFACE and INSTALL_INTERFACE generator expressions
   :post: Public/Interface headers are installed to their respective directories
   :post: Target EXPORT_NAME is set (strips project name prefix if present)

   .. note::
      **Directory handling:**

      - BUILD_INTERFACE: Points to source directory during build
      - INSTALL_INTERFACE: Points to install directory for consumers
      - PRIVATE directories are NOT exported to install interface

   .. note::
      **Export name stripping:**

      If target name starts with ``${PROJECT_NAME}_``, the prefix is removed for the export name.
      Example: ``myproject_core`` → export name ``core`` → imported as ``myproject::core``

   .. seealso::
      ``_cth_pkg_component_name`` uses this same EXPORT_NAME (falling back to the same prefix-stripping
      logic) to derive the package **component** name this target is installed under.

#]]
function(cth_pkg_target_include_directories TARGET_NAME)
    cth_assert_target("${TARGET_NAME}")
    set(oneValueArgs "")
    set(multiValueArgs PUBLIC PRIVATE INTERFACE)
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
    include(GNUInstallDirs)

    # --- strip project name prefix for EXPORT_NAME ---
    set(PREFIX_TO_STRIP "${PROJECT_NAME}_")
    string(FIND "${TARGET_NAME}" "${PREFIX_TO_STRIP}" PREFIX_POS)
    if(PREFIX_POS EQUAL 0)
        string(LENGTH "${PREFIX_TO_STRIP}" PREFIX_LENGTH)
        string(SUBSTRING "${TARGET_NAME}" ${PREFIX_LENGTH} -1 CLEAN_EXPORT_NAME)
        set_property(TARGET ${TARGET_NAME} PROPERTY EXPORT_NAME ${CLEAN_EXPORT_NAME})
    endif()

    # --- configure include directories ---
    foreach (SCOPE PUBLIC PRIVATE INTERFACE)
        if (DEFINED ARGS_${SCOPE})
            set(PROCESSED_DIRS "")
            foreach (DIR ${ARGS_${SCOPE}})
                list(APPEND PROCESSED_DIRS "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/${DIR}>")
                if (NOT "${SCOPE}" STREQUAL "PRIVATE")
                    list(APPEND PROCESSED_DIRS "$<INSTALL_INTERFACE:${DIR}>")
                endif ()
            endforeach ()
            target_include_directories(${TARGET_NAME} ${SCOPE} ${PROCESSED_DIRS})
        endif ()
    endforeach ()

    # --- install public headers (File-based install is safe to keep here) ---
    set(PUBLIC_HEADER_DIRS ${ARGS_PUBLIC} ${ARGS_INTERFACE})
    if(PUBLIC_HEADER_DIRS)
        list(REMOVE_DUPLICATES PUBLIC_HEADER_DIRS)
        foreach(DIR ${PUBLIC_HEADER_DIRS})
            install(DIRECTORY ${DIR}/ DESTINATION ${DIR})
        endforeach()
    endif()

    # Register Target
    get_property(INSTALLABLE_TARGETS GLOBAL PROPERTY _CTH_INSTALLABLE_TARGETS)
    if(NOT "${TARGET_NAME}" IN_LIST INSTALLABLE_TARGETS)
        list(APPEND INSTALLABLE_TARGETS ${TARGET_NAME})
        set_property(GLOBAL PROPERTY _CTH_INSTALLABLE_TARGETS ${INSTALLABLE_TARGETS})
    endif()
endfunction()

# _cth_pkg_component_name(<out_var> <target>)
# Internal helper. Computes the package COMPONENT name a registered target is installed under:
#   1. The target's EXPORT_NAME property, if set.
#   2. Else the target name with a leading "${PROJECT_NAME}_" prefix stripped (same logic as
#      cth_pkg_target_include_directories's EXPORT_NAME stripping).
#   3. Else the raw target name.
# The result is sanitized ("::" -> "_")
#]]
function(_cth_pkg_component_name OUT_VAR TARGET_NAME)
    get_target_property(_cth_export_name ${TARGET_NAME} EXPORT_NAME)

    if(_cth_export_name)
        set(_cth_component "${_cth_export_name}")
    else()
        set(PREFIX_TO_STRIP "${PROJECT_NAME}_")
        string(FIND "${TARGET_NAME}" "${PREFIX_TO_STRIP}" PREFIX_POS)
        if(PREFIX_POS EQUAL 0)
            string(LENGTH "${PREFIX_TO_STRIP}" PREFIX_LENGTH)
            string(SUBSTRING "${TARGET_NAME}" ${PREFIX_LENGTH} -1 _cth_component)
        else()
            set(_cth_component "${TARGET_NAME}")
        endif()
    endif()

    string(REPLACE "::" "_" _cth_component "${_cth_component}")

    set(${OUT_VAR} "${_cth_component}" PARENT_SCOPE)
endfunction()

# _cth_finalize_pkg_targets()
# Internal function. Installs each registered target into unique export set
# ("${PROJECT_NAME}_<component>-targets"), where <component> comes from _cth_pkg_component_name().
# Records the discovered components (_CTH_PKG_COMPONENTS global list) and _CTH_PKG_COMPONENT_TARGET_<component> 
# for _cth_setup_package().
#]]
function(_cth_finalize_pkg_targets)
    get_property(INSTALLABLE_TARGETS GLOBAL PROPERTY _CTH_INSTALLABLE_TARGETS)
    include(GNUInstallDirs)

    foreach(TGT ${INSTALLABLE_TARGETS})
        if(NOT TARGET ${TGT})
            continue()
        endif()

        _cth_pkg_component_name(COMPONENT_NAME ${TGT})
        set(EXPORT_SET_NAME "${PROJECT_NAME}_${COMPONENT_NAME}-targets")

        get_target_property(TGT_TYPE ${TGT} TYPE)

        set(INSTALL_COMPONENTS "")

        # 1. Standard Binaries
        if(NOT "${TGT_TYPE}" STREQUAL "INTERFACE_LIBRARY")
            list(APPEND INSTALL_COMPONENTS
                LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
                ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
                RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
            )
        endif()

        # 2. C++ Modules
        get_target_property(HAS_MODS ${TGT} CXX_MODULE_SETS)
        if(HAS_MODS)
            list(APPEND INSTALL_COMPONENTS
                FILE_SET CXX_MODULES DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/modules/${TGT}"
            )
        endif()

        install(TARGETS ${TGT}
                EXPORT "${EXPORT_SET_NAME}"
                ${INSTALL_COMPONENTS}
        )

        # --- register the component (deduped) and remember which target owns it ---
        get_property(REGISTERED_COMPONENTS GLOBAL PROPERTY _CTH_PKG_COMPONENTS)
        if(NOT "${COMPONENT_NAME}" IN_LIST REGISTERED_COMPONENTS)
            set_property(GLOBAL APPEND PROPERTY _CTH_PKG_COMPONENTS "${COMPONENT_NAME}")
        endif()
        set_property(GLOBAL PROPERTY _CTH_PKG_COMPONENT_TARGET_${COMPONENT_NAME} "${TGT}")
    endforeach()
endfunction()

# _cth_pkg_build_component_deps()
# Internal function. Computes the DIRECT inter-component dependency graph from each registered
# target's LINK_LIBRARIES / INTERFACE_LINK_LIBRARIES and stores it as
# _CTH_PKG_COMPONENT_DEPS_<component>. $<LINK_ONLY:...> entries are unwrapped; any other generator expression is ignored
# (no target <-> dependency resolve at configure possible); ALIAS targets are resolved.
# pre: _cth_finalize_pkg_targets() has populated _CTH_PKG_COMPONENTS / _CTH_PKG_COMPONENT_TARGET_<c>
#]]
function(_cth_pkg_build_component_deps)
    get_property(COMPONENTS GLOBAL PROPERTY _CTH_PKG_COMPONENTS)
    get_property(INSTALLABLE_TARGETS GLOBAL PROPERTY _CTH_INSTALLABLE_TARGETS)

    foreach(COMPONENT ${COMPONENTS})
        get_property(TGT GLOBAL PROPERTY _CTH_PKG_COMPONENT_TARGET_${COMPONENT})

        set(RAW_LIBS "")

        get_target_property(_cth_link_libs ${TGT} LINK_LIBRARIES)
        if(_cth_link_libs)
            list(APPEND RAW_LIBS ${_cth_link_libs})
        endif()

        get_target_property(_cth_iface_libs ${TGT} INTERFACE_LINK_LIBRARIES)
        if(_cth_iface_libs)
            list(APPEND RAW_LIBS ${_cth_iface_libs})
        endif()

        set(COMPONENT_DEPS "")

        foreach(ENTRY ${RAW_LIBS})
            set(RESOLVED "")

            if(ENTRY MATCHES "^\\$<LINK_ONLY:(.+)>$")
                # $<LINK_ONLY:...> wraps a real dependency name -- unwrap it.
                set(RESOLVED "${CMAKE_MATCH_1}")
            elseif(ENTRY MATCHES "^\\$<.*>$")
                # Any other generator expression can't be resolved to a target name here -- ignore it.
                continue()
            else()
                set(RESOLVED "${ENTRY}")
            endif()

            # Resolve ALIAS targets (only meaningful if RESOLVED is an existing target).
            if(TARGET ${RESOLVED})
                get_target_property(_cth_aliased ${RESOLVED} ALIASED_TARGET)
                if(_cth_aliased)
                    set(RESOLVED "${_cth_aliased}")
                endif()
            endif()

            # Only entries resolving to another registered (installable) target become a component
            # dependency; everything else (system libs, external packages, ...) is handled by
            # cth_pkg_target_find_package()'s recorded find_dependency() blocks instead.
            if(NOT "${RESOLVED}" STREQUAL "${TGT}" AND "${RESOLVED}" IN_LIST INSTALLABLE_TARGETS)
                _cth_pkg_component_name(RESOLVED_COMPONENT ${RESOLVED})
                list(APPEND COMPONENT_DEPS "${RESOLVED_COMPONENT}")
            endif()
        endforeach()

        if(COMPONENT_DEPS)
            list(REMOVE_DUPLICATES COMPONENT_DEPS)
        endif()

        set_property(GLOBAL PROPERTY _CTH_PKG_COMPONENT_DEPS_${COMPONENT} "${COMPONENT_DEPS}")
    endforeach()
endfunction()

# _cth_pkg_topo_visit_component(<component>)
# Internal helper for _cth_setup_package(): DFS visit for a dependency-first topological sort of
# package components. Uses GLOBAL properties as DFS state (rather than threading state through
# PARENT_SCOPE across recursive calls):
#   _CTH_PKG_TOPO_SORTED   -- result list, dependency-first
#   _CTH_PKG_TOPO_VISITED  -- fully processed components
#   _CTH_PKG_TOPO_VISITING -- components currently on the DFS stack (cycle detection)
# pre: _cth_pkg_build_component_deps() has computed _CTH_PKG_COMPONENT_DEPS_<component>
# post: FATAL_ERROR if a dependency cycle between components is detected
#]]
function(_cth_pkg_topo_visit_component COMPONENT)
    get_property(VISITED GLOBAL PROPERTY _CTH_PKG_TOPO_VISITED)
    if("${COMPONENT}" IN_LIST VISITED)
        return()
    endif()

    get_property(VISITING GLOBAL PROPERTY _CTH_PKG_TOPO_VISITING)
    if("${COMPONENT}" IN_LIST VISITING)
        message(FATAL_ERROR "cth: circular dependency detected between package components (involving '${COMPONENT}')")
    endif()

    set_property(GLOBAL APPEND PROPERTY _CTH_PKG_TOPO_VISITING "${COMPONENT}")

    get_property(DEPS GLOBAL PROPERTY _CTH_PKG_COMPONENT_DEPS_${COMPONENT})
    foreach(DEP ${DEPS})
        _cth_pkg_topo_visit_component("${DEP}")
    endforeach()

    get_property(VISITING GLOBAL PROPERTY _CTH_PKG_TOPO_VISITING)
    list(REMOVE_ITEM VISITING "${COMPONENT}")
    set_property(GLOBAL PROPERTY _CTH_PKG_TOPO_VISITING "${VISITING}")

    set_property(GLOBAL APPEND PROPERTY _CTH_PKG_TOPO_SORTED "${COMPONENT}")
    set_property(GLOBAL APPEND PROPERTY _CTH_PKG_TOPO_VISITED "${COMPONENT}")
endfunction()

# _cth_setup_package()
# Internal function. Component-aware: installs one export set per component, computes the
# inter-component dependency graph, a dependency-first topological order and transitive
# dependency closures, then generates a single "${PROJECT_NAME}Config.cmake" that lets consumers
# request a subset of components:
#
#   find_package(${PROJECT_NAME} CONFIG REQUIRED COMPONENTS <comp>...)
#
# Requesting no COMPONENTS loads every component.
#]]
function(_cth_setup_package)
    include(CMakePackageConfigHelpers)
    include(GNUInstallDirs)

    _cth_pkg_build_component_deps()

    get_property(COMPONENTS GLOBAL PROPERTY _CTH_PKG_COMPONENTS)
    cth_assert_not_empty("${COMPONENTS}" REASON "_cth_setup_package: no package components registered -- call cth_pkg_target_include_directories()/cth_pkg_target_add_modules() before cth_create_package()")

    set(NAMESPACE "${PROJECT_NAME}::")
    set(INSTALL_CONFIG_DIR "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}")

    # --- Part 1: install one export set per component ---
    foreach(COMPONENT ${COMPONENTS})
        set(EXPORT_SET_NAME "${PROJECT_NAME}_${COMPONENT}-targets")
        install(EXPORT ${EXPORT_SET_NAME}
                FILE "${EXPORT_SET_NAME}.cmake"
                NAMESPACE ${NAMESPACE}
                DESTINATION ${INSTALL_CONFIG_DIR}
                # Per-component module BMI folder
                CXX_MODULES_DIRECTORY "cmake/${PROJECT_NAME}-modules/${COMPONENT}"
        )
    endforeach()

    # --- Part 2: dependency-first topological order (with cycle detection) ---
    set_property(GLOBAL PROPERTY _CTH_PKG_TOPO_SORTED "")
    set_property(GLOBAL PROPERTY _CTH_PKG_TOPO_VISITED "")
    set_property(GLOBAL PROPERTY _CTH_PKG_TOPO_VISITING "")

    foreach(COMPONENT ${COMPONENTS})
        _cth_pkg_topo_visit_component("${COMPONENT}")
    endforeach()

    get_property(SORTED_COMPONENTS GLOBAL PROPERTY _CTH_PKG_TOPO_SORTED)

    # --- Part 3: transitive dependency closures ---
    # Topo order makes this a single forward pass: by the time we reach COMPONENT, every one of
    # its dependencies has already had its own closure computed.
    foreach(COMPONENT ${SORTED_COMPONENTS})
        get_property(DIRECT_DEPS GLOBAL PROPERTY _CTH_PKG_COMPONENT_DEPS_${COMPONENT})

        set(CLOSURE "")
        foreach(DEP ${DIRECT_DEPS})
            list(APPEND CLOSURE "${DEP}")
            get_property(DEP_CLOSURE GLOBAL PROPERTY _CTH_PKG_COMPONENT_CLOSURE_${DEP})
            list(APPEND CLOSURE ${DEP_CLOSURE})
        endforeach()

        if(CLOSURE)
            list(REMOVE_DUPLICATES CLOSURE)
        endif()

        set_property(GLOBAL PROPERTY _CTH_PKG_COMPONENT_CLOSURE_${COMPONENT} "${CLOSURE}")
    endforeach()

    # --- Part 4: generate the Config.cmake.in content ---
    # VAR_PREFIX names every variable the generated file defines, so it can't collide with
    # anything already in a consumer's scope.
    set(VAR_PREFIX "_${PROJECT_NAME}_")

    set(CONFIG_CONTENT "@PACKAGE_INIT@\n\n")
    string(APPEND CONFIG_CONTENT "include(CMakeFindDependencyMacro)\n\n")

    # (b) literal list of every known component, dependency-first
    string(APPEND CONFIG_CONTENT "set(${VAR_PREFIX}all_components \"${SORTED_COMPONENTS}\")\n")

    # (c) per-component transitive closures (emitted for every component, empty or not)
    foreach(COMPONENT ${SORTED_COMPONENTS})
        get_property(CLOSURE GLOBAL PROPERTY _CTH_PKG_COMPONENT_CLOSURE_${COMPONENT})
        string(APPEND CONFIG_CONTENT "set(${VAR_PREFIX}closure_${COMPONENT} \"${CLOSURE}\")\n")
    endforeach()
    string(APPEND CONFIG_CONTENT "\n")

    # (d) normalize requested component names ("::" -> "_") while keeping the originals, so both
    #     COMPONENTS win::capture and COMPONENTS win_capture work.
    string(APPEND CONFIG_CONTENT
        "set(${VAR_PREFIX}requested_original \"\${${PROJECT_NAME}_FIND_COMPONENTS}\")\n"
        "set(${VAR_PREFIX}requested_normalized \"\")\n"
        "foreach(${VAR_PREFIX}c IN LISTS ${VAR_PREFIX}requested_original)\n"
        "    string(REPLACE \"::\" \"_\" ${VAR_PREFIX}cn \"\${${VAR_PREFIX}c}\")\n"
        "    list(APPEND ${VAR_PREFIX}requested_normalized \"\${${VAR_PREFIX}cn}\")\n"
        "endforeach()\n\n"
    )

    # (e) no components requested -> load everything (backwards compatible)
    string(APPEND CONFIG_CONTENT
        "if(NOT ${VAR_PREFIX}requested_normalized)\n"
        "    set(${VAR_PREFIX}requested_normalized \"${SORTED_COMPONENTS}\")\n"
        "    set(${VAR_PREFIX}requested_original \"${SORTED_COMPONENTS}\")\n"
        "endif()\n\n"
    )

    # (f) flag unknown requested components. No FATAL_ERROR/return() here -- just flip the
    #     relevant *_FOUND flags to FALSE; check_required_components() does the actual failing.
    string(APPEND CONFIG_CONTENT
        "list(LENGTH ${VAR_PREFIX}requested_normalized ${VAR_PREFIX}num_requested)\n"
        "if(${VAR_PREFIX}num_requested GREATER 0)\n"
        "    math(EXPR ${VAR_PREFIX}last_idx \"\${${VAR_PREFIX}num_requested} - 1\")\n"
        "    foreach(${VAR_PREFIX}i RANGE 0 \${${VAR_PREFIX}last_idx})\n"
        "        list(GET ${VAR_PREFIX}requested_normalized \${${VAR_PREFIX}i} ${VAR_PREFIX}comp)\n"
        "        list(GET ${VAR_PREFIX}requested_original \${${VAR_PREFIX}i} ${VAR_PREFIX}orig)\n"
        "\n"
        "        list(FIND ${VAR_PREFIX}all_components \"\${${VAR_PREFIX}comp}\" ${VAR_PREFIX}known_idx)\n"
        "        if(${VAR_PREFIX}known_idx EQUAL -1)\n"
        "            set(${PROJECT_NAME}_\${${VAR_PREFIX}comp}_FOUND FALSE)\n"
        "            if(${PROJECT_NAME}_FIND_REQUIRED_\${${VAR_PREFIX}orig})\n"
        "                set(${PROJECT_NAME}_FOUND FALSE)\n"
        "                string(APPEND ${PROJECT_NAME}_NOT_FOUND_MESSAGE \"Requested component '\${${VAR_PREFIX}orig}' is not a known ${PROJECT_NAME} component.\\n\")\n"
        "            endif()\n"
        "        endif()\n"
        "    endforeach()\n"
        "endif()\n\n"
    )

    # (g) load set = requested (normalized) components + their transitive closures
    string(APPEND CONFIG_CONTENT
        "set(${VAR_PREFIX}load \"\")\n"
        "foreach(${VAR_PREFIX}c IN LISTS ${VAR_PREFIX}requested_normalized)\n"
        "    list(FIND ${VAR_PREFIX}all_components \"\${${VAR_PREFIX}c}\" ${VAR_PREFIX}known_idx)\n"
        "    if(NOT ${VAR_PREFIX}known_idx EQUAL -1)\n"
        "        list(APPEND ${VAR_PREFIX}load \"\${${VAR_PREFIX}c}\")\n"
        "        list(APPEND ${VAR_PREFIX}load \${${VAR_PREFIX}closure_\${${VAR_PREFIX}c}})\n"
        "    endif()\n"
        "endforeach()\n"
        "if(${VAR_PREFIX}load)\n"
        "    list(REMOVE_DUPLICATES ${VAR_PREFIX}load)\n"
        "endif()\n\n"
    )

    # (g, cont'd) one unrolled, straight-line load block per component (no loops/macros over
    # components in the generated file), in dependency-first order so a component's
    # find_dependency() checks always run before its dependents include their targets file.
    foreach(COMPONENT ${SORTED_COMPONENTS})
        get_property(TGT GLOBAL PROPERTY _CTH_PKG_COMPONENT_TARGET_${COMPONENT})
        get_property(CHECK_BLOCK GLOBAL PROPERTY _CTH_PKG_DEPENDENCIES_${TGT})

        string(APPEND CONFIG_CONTENT
            "list(FIND ${VAR_PREFIX}load \"${COMPONENT}\" ${VAR_PREFIX}idx)\n"
            "if(NOT ${VAR_PREFIX}idx EQUAL -1)\n"
        )
        if(CHECK_BLOCK)
            string(APPEND CONFIG_CONTENT "${CHECK_BLOCK}\n")
        endif()
        string(APPEND CONFIG_CONTENT
            "    include(\"\${CMAKE_CURRENT_LIST_DIR}/${PROJECT_NAME}_${COMPONENT}-targets.cmake\")\n"
            "    set(${PROJECT_NAME}_${COMPONENT}_FOUND TRUE)\n"
            "endif()\n\n"
        )
    endforeach()

    # (h) mirror FOUND flags back onto the originally-requested (non-normalized) names, so
    #     check_required_components() sees the exact names the consumer passed in.
    string(APPEND CONFIG_CONTENT
        "if(${VAR_PREFIX}num_requested GREATER 0)\n"
        "    foreach(${VAR_PREFIX}i RANGE 0 \${${VAR_PREFIX}last_idx})\n"
        "        list(GET ${VAR_PREFIX}requested_normalized \${${VAR_PREFIX}i} ${VAR_PREFIX}comp)\n"
        "        list(GET ${VAR_PREFIX}requested_original \${${VAR_PREFIX}i} ${VAR_PREFIX}orig)\n"
        "        if(NOT ${VAR_PREFIX}comp STREQUAL ${VAR_PREFIX}orig)\n"
        "            set(${PROJECT_NAME}_\${${VAR_PREFIX}orig}_FOUND \"\${${PROJECT_NAME}_\${${VAR_PREFIX}comp}_FOUND}\")\n"
        "        endif()\n"
        "    endforeach()\n"
        "endif()\n\n"
    )

    # (i) check_required_components() reads the ${PROJECT_NAME}_FOUND / *_<component>_FOUND flags
    # set above and fails appropriately for FIND_REQUIRED / non-QUIET consumers.
    string(APPEND CONFIG_CONTENT "check_required_components(${PROJECT_NAME})\n")

    set(TEMP_CONFIG_IN_PATH "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake.in")
    file(WRITE ${TEMP_CONFIG_IN_PATH} "${CONFIG_CONTENT}")

    configure_package_config_file(${TEMP_CONFIG_IN_PATH}
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
            INSTALL_DESTINATION ${INSTALL_CONFIG_DIR}
    )

    write_basic_package_version_file(
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
            VERSION ${PROJECT_VERSION}
            COMPATIBILITY AnyNewerVersion
    )

    install(FILES
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
            DESTINATION ${INSTALL_CONFIG_DIR}
    )
endfunction()

# _cth_add_pkg_target()
# builds and installs all registered package targets
# creates a custom target named "${PROJECT_NAME}_install"
# pre: _CTH_INSTALLABLE_TARGETS global property is not empty
#]]
function(_cth_add_pkg_target)
    get_property(INSTALLABLE_TARGETS GLOBAL PROPERTY _CTH_INSTALLABLE_TARGETS)
    cth_assert_not_empty("${INSTALLABLE_TARGETS}" "No installable targets were registered — use cth_pkg_target_include_directories or add to _CTH_INSTALLABLE_TARGETS manually")

    set(INSTALL_TARGET_NAME "${PROJECT_NAME}_package")
    set(INSTALL_COMMENT "Packaging ${PROJECT_NAME} project...")

    # --- FIX START: Filter out INTERFACE libraries from build dependencies ---
    set(BUILDABLE_TARGETS "")
    foreach(TGT ${INSTALLABLE_TARGETS})
        get_target_property(TGT_TYPE ${TGT} TYPE)
        # We only add to DEPENDS if it creates a real file (Static/Shared Lib or Executable)
        # INTERFACE_LIBRARY does not create a file, so we skip it here.
        if(NOT "${TGT_TYPE}" STREQUAL "INTERFACE_LIBRARY")
            list(APPEND BUILDABLE_TARGETS ${TGT})
        endif()
    endforeach()
    # --- FIX END ---

    set(PKG_DUMMY_SOURCE "${CMAKE_BINARY_DIR}/_pkg_dummy_source.cpp")
    if(WIN32)
        file(WRITE ${PKG_DUMMY_SOURCE}
            "#define WIN32_LEAN_AND_MEAN\n"
            "#include <Windows.h>\n"
            "int WINAPI WinMain(HINSTANCE, HINSTANCE, LPSTR, int) { return 0; }\n"
        )
        add_executable(${INSTALL_TARGET_NAME} WIN32 ${PKG_DUMMY_SOURCE})
    else()
        file(WRITE ${PKG_DUMMY_SOURCE}
            "#include<print>\n int main() { std::println(\"installed :)\"); return 0; }"
        )
        add_executable(${INSTALL_TARGET_NAME} ${PKG_DUMMY_SOURCE})
    endif()

    # --- guard: packaging into the default install prefix is almost never intended ---
    set(PKG_GUARD_SCRIPT "${CMAKE_BINARY_DIR}/_pkg_prefix_guard.cmake")
    set(PKG_PREFIX_IS_DEFAULT FALSE)
    if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
        set(PKG_PREFIX_IS_DEFAULT TRUE)
    endif()
    file(WRITE ${PKG_GUARD_SCRIPT}
        "if(${PKG_PREFIX_IS_DEFAULT})\n"
        "    message(FATAL_ERROR \"${PROJECT_NAME}: refusing to package into the default install prefix ('${CMAKE_INSTALL_PREFIX}') - set CMAKE_INSTALL_PREFIX explicitly\")\n"
        "endif()\n"
    )

    add_custom_target(_do_${INSTALL_TARGET_NAME}_install
            COMMAND ${CMAKE_COMMAND} -P "${PKG_GUARD_SCRIPT}"
            COMMAND ${CMAKE_COMMAND} --install . --prefix "${CMAKE_INSTALL_PREFIX}"
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
            COMMENT "${INSTALL_COMMENT}"
            DEPENDS ${BUILDABLE_TARGETS}  # <--- Use the filtered list here
    )

    add_dependencies(${INSTALL_TARGET_NAME} _do_${INSTALL_TARGET_NAME}_install)
endfunction()


#[[.rst:
.. command:: cth_create_package

   .. code-block:: cmake

      cth_create_package()

   Finalizes and creates the installable package for the project.

   :post: All registered targets are finalized for installation, each into its own package
          component export set (see ``_cth_pkg_component_name``)
   :post: A single component-aware package config and version file are generated
   :post: Package target named ``${PROJECT_NAME}_package`` is created

   .. note::
      This function orchestrates the complete package creation process:

      1. Finalizes all registered installable targets (one export set per component)
      2. Generates the CMake package configuration files (topological component dependency
         resolution + closures, see ``_cth_setup_package``)
      3. Creates a custom build target for packaging

   .. note::
      After calling this, build the ``${PROJECT_NAME}_package`` target to create the package.

   .. note::
      **Consumer usage:** ``find_package(${PROJECT_NAME} CONFIG REQUIRED COMPONENTS <comp>...)``
      loads only the requested components.

#]]
function(cth_create_package)
    _cth_finalize_pkg_targets()
    _cth_setup_package()
    _cth_add_pkg_target()
endfunction()
