cth_assert_not_cmd(cth_package_target_add_modules)
# cth_package_target_add_modules(<target_name> [PUBLIC <files...>] [PRIVATE <files...>])
# Adds C++ module files to a target.
# pre: target_name exists
# pre: target_name is not an INTERFACE library
# pre: PUBLIC or PRIVATE arguments are provided
function(cth_package_target_add_modules TARGET_NAME)
    # 1. Basic existence check
    cth_assert_target("${TARGET_NAME}")

    # 2. Interface check (C++ Modules cannot be added to INTERFACE libraries)
    get_target_property(TGT_TYPE ${TARGET_NAME} TYPE)
    cth_assert_if_not("${TGT_TYPE} STREQUAL \"INTERFACE_LIBRARY\"" 
        "'${TARGET_NAME}' is an INTERFACE library which do NOT support modules")

    set(options "")
    set(oneValueArgs "")
    set(multiValueArgs PUBLIC PRIVATE)
    cmake_parse_arguments(ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    cth_assert_if("(\"PUBLIC\" IN_LIST ARGN) OR (\"PRIVATE\" IN_LIST ARGN)"
        "No visibility specifiers (PUBLIC/PRIVATE) found for target '${TARGET_NAME}'.")

    # enable modules & scanning
    set_target_properties(
        ${TARGET_NAME} PROPERTIES
        CXX_SCAN_FOR_MODULES ON
    )

    # 3. Private Modules
    if(ARGS_PRIVATE)
        target_sources(${TARGET_NAME} PRIVATE 
            FILE_SET "${TARGET_NAME}_private_modules" TYPE CXX_MODULES FILES ${ARGS_PRIVATE}
        )
    endif()

    # 4. Public Modules
    if(ARGS_PUBLIC)
        target_sources(${TARGET_NAME} PUBLIC 
            FILE_SET CXX_MODULES TYPE CXX_MODULES FILES ${ARGS_PUBLIC}
        )
    endif()
    
    # Register Target for installation logic
    get_property(INSTALLABLE_TARGETS GLOBAL PROPERTY _CTH_INSTALLABLE_TARGETS)
    if(NOT "${TARGET_NAME}" IN_LIST INSTALLABLE_TARGETS)
        list(APPEND INSTALLABLE_TARGETS ${TARGET_NAME})
        set_property(GLOBAL PROPERTY _CTH_INSTALLABLE_TARGETS "${INSTALLABLE_TARGETS}")
    endif()
endfunction()

cth_assert_not_cmd(cth_package_target_find_package)
# cth_package_target_find_package(<target_name> <find_package_args>...)
# Wraps find_package to ensure dependencies are found during build
# AND recorded for the generated package configuration file using find_dependency.
function(cth_package_target_find_package TARGET_NAME)
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
    set_property(GLOBAL APPEND_STRING PROPERTY _CTH_PACKAGE_DEPENDENCIES "${CHECK_BLOCK}\n")
endfunction()

cth_assert_not_cmd(cth_package_target_include_directories)
# cth_package_target_include_directories(<target_name> [PUBLIC|PRIVATE|INTERFACE] <dirs>...)
# pre: target_name exists
function(cth_package_target_include_directories TARGET_NAME)
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

cth_assert_not_cmd(_cth_finalize_package_targets)
# _cth_finalize_package_targets()
# Internal function that performs the actual install(TARGETS) call.
function(_cth_finalize_package_targets)
    get_property(INSTALLABLE_TARGETS GLOBAL PROPERTY _CTH_INSTALLABLE_TARGETS)
    include(GNUInstallDirs)
    
    # We use a consistent export set name based on the project name
    set(EXPORT_SET_NAME "${PROJECT_NAME}-targets")

    foreach(TGT ${INSTALLABLE_TARGETS})
        if(NOT TARGET ${TGT})
            continue()
        endif()

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
    endforeach()
endfunction()





cth_assert_not_cmd(_cth_setup_package)
# _cth_setup_package()
# Updated to support C++ Module metadata export.
function(_cth_setup_package)
    include(CMakePackageConfigHelpers)
    include(GNUInstallDirs)

    set(EXPORT_SET_NAME "${PROJECT_NAME}-targets")
    set(NAMESPACE "${PROJECT_NAME}::")
    set(INSTALL_CONFIG_DIR "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}")
    set(TARGETS_FILENAME "${EXPORT_SET_NAME}.cmake")

    # --- Part 1: Install the Export Set ---
    install(EXPORT ${EXPORT_SET_NAME}
            FILE ${TARGETS_FILENAME}
            NAMESPACE ${NAMESPACE}
            DESTINATION ${INSTALL_CONFIG_DIR}
            # Module BMI folder
            CXX_MODULES_DIRECTORY "cmake/${PROJECT_NAME}-modules" 
    )

    # --- Part 2: Auto-generate and Install Config/Version files ---
    get_property(PACKAGE_DEPENDENCIES GLOBAL PROPERTY _CTH_PACKAGE_DEPENDENCIES)

    set(TEMP_CONFIG_IN_PATH "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake.in")
    file(WRITE ${TEMP_CONFIG_IN_PATH}
            "@PACKAGE_INIT@\n\n"
            "include(CMakeFindDependencyMacro)\n"
            "${PACKAGE_DEPENDENCIES}\n"
            "include(\"\${CMAKE_CURRENT_LIST_DIR}/${TARGETS_FILENAME}\")\n"
    )

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

cth_assert_not_cmd(_cth_add_package_target)
# _cth_add_package_target()
# builds and installs all registered package targets
# creates a custom target named "${PROJECT_NAME}_install"
# pre: INSTALLABLE_TARGETS property is not empty
function(_cth_add_package_target)
    get_property(INSTALLABLE_TARGETS GLOBAL PROPERTY _CTH_INSTALLABLE_TARGETS)
    cth_assert_if("INSTALLABLE_TARGETS" "No installable targets were registered — use cth_package_target_include_directories or add to _CTH_INSTALLABLE_TARGETS manually")

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

    set(PACKAGE_DUMMY_SOURCE "${CMAKE_BINARY_DIR}/_package_dummy_source.cpp")
    if(WIN32)
        file(WRITE ${PACKAGE_DUMMY_SOURCE} 
            "#define WIN32_LEAN_AND_MEAN\n"
            "#include <Windows.h>\n"
            "int WINAPI WinMain(HINSTANCE, HINSTANCE, LPSTR, int) { return 0; }\n"
        )
        add_executable(${INSTALL_TARGET_NAME} WIN32 ${PACKAGE_DUMMY_SOURCE})
    else()
        file(WRITE ${PACKAGE_DUMMY_SOURCE}
            "#include<print>\n int main() { std::println(\"installed :)\"); return 0; }"
        )
        add_executable(${INSTALL_TARGET_NAME} ${PACKAGE_DUMMY_SOURCE})
    endif()

    add_custom_target(_do_${INSTALL_TARGET_NAME}_install
            COMMAND ${CMAKE_COMMAND} -E rm -rf "${CMAKE_INSTALL_PREFIX}"
            COMMAND ${CMAKE_COMMAND} --install . --prefix "${CMAKE_INSTALL_PREFIX}"
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
            COMMENT "${INSTALL_COMMENT}"
            DEPENDS ${BUILDABLE_TARGETS}  # <--- Use the filtered list here
    )

    add_dependencies(${INSTALL_TARGET_NAME} _do_${INSTALL_TARGET_NAME}_install)
endfunction()


cth_assert_not_cmd(cth_create_package)
# cth_create_package()
# packages the project by setting up the package
function(cth_create_package)
    _cth_finalize_package_targets()
    _cth_setup_package()
    _cth_add_package_target()
endfunction()