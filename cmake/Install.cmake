# =============================================================================
# CloudCompare Install.cmake
# =============================================================================
# This module provides installation functions for CloudCompare libraries,
# plugins, and files. Updated to support CMake package configuration export.
#
# Key Functions:
#   InstallSharedLibrary - Install shared libraries with optional export
#   InstallFiles - Install non-target files
#   InstallPlugins - Install plugins
#   InstallHeaders - Install public header files (NEW)
#   CloudCompareInstallPackageConfig - Install CMake package config files (NEW)
# =============================================================================

include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

# =============================================================================
# Global Options for Package Configuration
# =============================================================================

option(CLOUDCOMPARE_INSTALL_CMAKE_CONFIG 
    "Generate and install CMake package configuration files" ON)

option(CLOUDCOMPARE_REGISTER_PACKAGE 
    "Register CloudCompare package in CMake registry" OFF)

# Define the list of targets to be exported
set(CLOUDCOMPARE_EXPORT_TARGETS "" CACHE INTERNAL "List of CloudCompare export targets")

# =============================================================================
# InstallSharedLibrary
# =============================================================================
# Install a shared library in the correct places for each platform.
# Now supports EXPORT for CMake package configuration.
#
# Arguments:
#   TARGET          The name of the library target
#   EXPORT          (Optional) Add to CloudCompareTargets export set
#   HEADERS         (Optional) List of public header files to install
#   HEADERS_DIR     (Optional) Directory containing headers to install
#   HEADERS_DEST    (Optional) Destination subdirectory for headers
#
function(InstallSharedLibrary)
    if(NOT INSTALL_DESTINATIONS)
        return()
    endif()

    cmake_parse_arguments(
        INSTALL_SHARED_LIB
        "EXPORT"
        "TARGET;HEADERS_DIR;HEADERS_DEST"
        "HEADERS"
        ${ARGN}
    )

    # For readability
    set(shared_lib_target "${INSTALL_SHARED_LIB_TARGET}")
    message(STATUS "Install shared library: ${shared_lib_target}")

    # Add to export targets list if EXPORT is specified
    if(INSTALL_SHARED_LIB_EXPORT AND CLOUDCOMPARE_INSTALL_CMAKE_CONFIG)
        set(CLOUDCOMPARE_EXPORT_TARGETS 
            ${CLOUDCOMPARE_EXPORT_TARGETS} ${shared_lib_target} 
            CACHE INTERNAL "List of CloudCompare export targets")
        message(STATUS "  -> Added to CloudCompareTargets export")
    endif()

    foreach(destination ${INSTALL_DESTINATIONS})
        if(UNIX AND NOT APPLE)
            set(destination ${LINUX_INSTALL_SHARED_DESTINATION})
        endif()

        _InstallSharedTarget(
            TARGET ${shared_lib_target}
            DEST_PATH ${destination}
            ${INSTALL_SHARED_LIB_EXPORT}
        )
    endforeach()

    # Install headers if specified
    if(INSTALL_SHARED_LIB_HEADERS OR INSTALL_SHARED_LIB_HEADERS_DIR)
        _InstallLibraryHeaders(
            TARGET ${shared_lib_target}
            HEADERS ${INSTALL_SHARED_LIB_HEADERS}
            HEADERS_DIR ${INSTALL_SHARED_LIB_HEADERS_DIR}
            HEADERS_DEST ${INSTALL_SHARED_LIB_HEADERS_DEST}
        )
    endif()
endfunction()

# =============================================================================
# InstallFiles
# =============================================================================
# Install files that are not targets.
#
# Arguments:
#   FILES The name of the files to install
#
function(InstallFiles)
    if(NOT INSTALL_DESTINATIONS)
        return()
    endif()
    
    cmake_parse_arguments(
        INSTALL_FILES
        ""
        ""
        "FILES"
        ${ARGN}
    )

    # For readability
    set(files "${INSTALL_FILES_FILES}")

    if(NOT files)
        message(WARNING "InstallFiles: no files specified")
        return()
    endif()
    
    message(STATUS "Install files: ${files} to ${INSTALL_DESTINATIONS}")
    
    foreach(destination ${INSTALL_DESTINATIONS})            
        _InstallFiles(
            FILES ${files}
            DEST_PATH ${destination}
        )        
    endforeach()
endfunction()

# =============================================================================
# InstallHeaders (NEW)
# =============================================================================
# Install public header files for a library.
#
# Arguments:
#   TARGET          The library target name (used for destination subdirectory)
#   HEADERS         List of individual header files to install
#   HEADERS_DIR     Directory containing headers to install (recursive)
#   DESTINATION     Custom destination path (optional)
#   COMPONENT       Installation component (default: Development)
#
function(InstallHeaders)
    cmake_parse_arguments(
        INSTALL_HEADERS
        ""
        "TARGET;HEADERS_DIR;DESTINATION;COMPONENT"
        "HEADERS"
        ${ARGN}
    )

    # Default component
    if(NOT INSTALL_HEADERS_COMPONENT)
        set(INSTALL_HEADERS_COMPONENT "Development")
    endif()

    # Determine destination
    if(INSTALL_HEADERS_DESTINATION)
        set(headers_dest "${INSTALL_HEADERS_DESTINATION}")
    elseif(INSTALL_HEADERS_TARGET)
        set(headers_dest "${CMAKE_INSTALL_INCLUDEDIR}/cloudcompare/${INSTALL_HEADERS_TARGET}")
    else()
        set(headers_dest "${CMAKE_INSTALL_INCLUDEDIR}/cloudcompare")
    endif()

    # Install individual headers
    if(INSTALL_HEADERS_HEADERS)
        install(
            FILES ${INSTALL_HEADERS_HEADERS}
            DESTINATION "${headers_dest}"
            COMPONENT ${INSTALL_HEADERS_COMPONENT}
        )
        message(STATUS "Install headers for ${INSTALL_HEADERS_TARGET}: ${headers_dest}")
    endif()

    # Install headers from directory
    if(INSTALL_HEADERS_HEADERS_DIR AND EXISTS "${INSTALL_HEADERS_HEADERS_DIR}")
        install(
            DIRECTORY "${INSTALL_HEADERS_HEADERS_DIR}/"
            DESTINATION "${headers_dest}"
            COMPONENT ${INSTALL_HEADERS_COMPONENT}
            FILES_MATCHING 
                PATTERN "*.h"
                PATTERN "*.hpp"
                PATTERN "*.hxx"
                PATTERN "*.inl"
        )
        message(STATUS "Install headers directory for ${INSTALL_HEADERS_TARGET}: ${INSTALL_HEADERS_HEADERS_DIR} -> ${headers_dest}")
    endif()
endfunction()

# =============================================================================
# InstallPlugins
# =============================================================================
# Install plugins to the specified destination.
#
# Arguments:
#   DEST_FOLDER        The name of the directory to install the plugins in.
#   DEST_PATH          Path to DEST_FOLDER
#   SHADER_DEST_FOLDER The name of the directory to install the shaders
#   SHADER_DEST_PATH   Path to SHADER_DEST_FOLDER
#   TYPES              Semicolon-separated list of plugin types (gl, io, standard)
#
function(InstallPlugins)
    cmake_parse_arguments(
        INSTALL_PLUGINS
        ""
        "DEST_FOLDER;DEST_PATH;SHADER_DEST_FOLDER;SHADER_DEST_PATH"
        "TYPES"
        ${ARGN}
    )
    
    # Check the types we need to install
    set(VALID_TYPES "gl" "io" "standard")
    
    # If TYPES was not specified, use all of them
    if(NOT INSTALL_PLUGINS_TYPES)
        set(INSTALL_PLUGINS_TYPES "${VALID_TYPES}")
    else()
        foreach(type ${INSTALL_PLUGINS_TYPES})
            if(NOT "${type}" IN_LIST VALID_TYPES)           
                string(REPLACE ";" ", " VALID_TYPES_STR "${VALID_TYPES}")
                message(FATAL_ERROR "InstallPlugins: Did not find proper TYPES. Valid values are: ${VALID_TYPES_STR}")
            endif()
        endforeach()
    endif()
    
    message(STATUS "Install plugins")
    message(STATUS " Types: ${INSTALL_PLUGINS_TYPES}")
    
    # Check our destination path is valid
    if(NOT INSTALL_PLUGINS_DEST_PATH)
        message(FATAL_ERROR "InstallPlugins: DEST_PATH not specified")
    endif()
    
    message(STATUS " Destination: ${INSTALL_PLUGINS_DEST_PATH}/${INSTALL_PLUGINS_DEST_FOLDER}")
    
    # If we have gl plugins, check that our shader destination folder is valid
    if("gl" IN_LIST VALID_TYPES)
        if(NOT INSTALL_PLUGINS_SHADER_DEST_PATH)
            message(FATAL_ERROR "InstallPlugins: SHADER_DEST_PATH not specified")
        endif()
        
        message(STATUS " Shader Destination: ${INSTALL_PLUGINS_SHADER_DEST_PATH}/${INSTALL_PLUGINS_SHADER_DEST_FOLDER}")
    endif()

    # Make CloudCompare/ccViewer depend on the plugins
    if(CC_PLUGIN_TARGET_LIST)
        add_dependencies(${PROJECT_NAME} ${CC_PLUGIN_TARGET_LIST})
    endif()

    # Install the requested plugins in the DEST_FOLDER
    foreach(plugin_target ${CC_PLUGIN_TARGET_LIST})
        get_target_property(plugin_type ${plugin_target} PLUGIN_TYPE)
        
        if("${plugin_type}" IN_LIST INSTALL_PLUGINS_TYPES)
            message(STATUS " Install ${plugin_target} (${plugin_type})")
            
            _InstallSharedTarget(
                TARGET ${plugin_target}
                DEST_PATH ${INSTALL_PLUGINS_DEST_PATH}
                DEST_FOLDER ${INSTALL_PLUGINS_DEST_FOLDER}
            )        
            
            if("${plugin_type}" STREQUAL "gl")
                get_target_property(SHADER_FOLDER_NAME ${plugin_target} SHADER_FOLDER_NAME)
                get_target_property(SHADER_FOLDER_PATH ${plugin_target} SHADER_FOLDER_PATH)
                
                if(EXISTS "${SHADER_FOLDER_PATH}")
                    message(STATUS "  + shader: ${SHADER_FOLDER_NAME} (${SHADER_FOLDER_PATH})")
                    
                    get_target_property(shader_files ${plugin_target} SOURCES)
                    list(FILTER shader_files INCLUDE REGEX ".*\.vert|frag")                    
                    
                    _InstallFiles(
                        FILES ${shader_files}
                        DEST_PATH ${INSTALL_PLUGINS_SHADER_DEST_PATH}
                        DEST_FOLDER ${INSTALL_PLUGINS_SHADER_DEST_FOLDER}/${SHADER_FOLDER_NAME}
                    )
                endif()
            endif()
        endif()
    endforeach()
endfunction()

# =============================================================================
# CloudCompareInstallPackageConfig (NEW)
# =============================================================================
# Generate and install CMake package configuration files.
# Call this at the end of your main CMakeLists.txt after all targets are defined.
#
# Arguments:
#   VERSION         CloudCompare version string
#   COMPATIBILITY   Version compatibility mode (default: SameMajorVersion)
#
function(CloudCompareInstallPackageConfig)
    if(NOT CLOUDCOMPARE_INSTALL_CMAKE_CONFIG)
        message(STATUS "CloudCompare CMake config installation is disabled")
        return()
    endif()

    cmake_parse_arguments(
        CC_PKG
        ""
        "VERSION;COMPATIBILITY"
        ""
        ${ARGN}
    )

    # Set defaults
    if(NOT CC_PKG_VERSION)
        if(DEFINED CLOUDCOMPARE_VERSION)
            set(CC_PKG_VERSION "${CLOUDCOMPARE_VERSION}")
        elseif(DEFINED PROJECT_VERSION)
            set(CC_PKG_VERSION "${PROJECT_VERSION}")
        else()
            set(CC_PKG_VERSION "2.13.0")
        endif()
    endif()

    if(NOT CC_PKG_COMPATIBILITY)
        set(CC_PKG_COMPATIBILITY "SameMajorVersion")
    endif()

    # Parse version components
    string(REGEX MATCH "^([0-9]+)\\.([0-9]+)\\.?([0-9]*)$" _version_match "${CC_PKG_VERSION}")
    set(PROJECT_VERSION "${CC_PKG_VERSION}")
    set(PROJECT_VERSION_MAJOR "${CMAKE_MATCH_1}")
    set(PROJECT_VERSION_MINOR "${CMAKE_MATCH_2}")
    set(PROJECT_VERSION_PATCH "${CMAKE_MATCH_3}")
    if(NOT PROJECT_VERSION_PATCH)
        set(PROJECT_VERSION_PATCH "0")
    endif()

    message(STATUS "")
    message(STATUS "=== CloudCompare CMake Package Configuration ===")
    message(STATUS "  Version: ${CC_PKG_VERSION}")

    # Define installation directories
    set(CLOUDCOMPARE_CONFIG_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}/cmake/CloudCompare")
    
    if(UNIX AND NOT APPLE)
        set(CLOUDCOMPARE_INCLUDE_INSTALL_DIR "${CMAKE_INSTALL_INCLUDEDIR}/cloudcompare")
        set(CLOUDCOMPARE_LIB_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}/cloudcompare")
        set(CLOUDCOMPARE_PLUGIN_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}/cloudcompare/plugins")
    elseif(APPLE)
        set(CLOUDCOMPARE_INCLUDE_INSTALL_DIR "${CMAKE_INSTALL_INCLUDEDIR}/cloudcompare")
        set(CLOUDCOMPARE_LIB_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}")
        set(CLOUDCOMPARE_PLUGIN_INSTALL_DIR "${CLOUDCOMPARE_MAC_BASE_DIR}/Contents/PlugIns")
    else()
        set(CLOUDCOMPARE_INCLUDE_INSTALL_DIR "${CMAKE_INSTALL_INCLUDEDIR}/cloudcompare")
        set(CLOUDCOMPARE_LIB_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}")
        set(CLOUDCOMPARE_PLUGIN_INSTALL_DIR "${CLOUDCOMPARE_DEST_FOLDER}/plugins")
    endif()

    message(STATUS "  Config install dir: ${CLOUDCOMPARE_CONFIG_INSTALL_DIR}")
    message(STATUS "  Include install dir: ${CLOUDCOMPARE_INCLUDE_INSTALL_DIR}")
    message(STATUS "  Library install dir: ${CLOUDCOMPARE_LIB_INSTALL_DIR}")
    message(STATUS "  Plugin install dir: ${CLOUDCOMPARE_PLUGIN_INSTALL_DIR}")

    # Detect Qt version
    if(TARGET Qt6::Core)
        set(QT_VERSION_MAJOR 6)
    elseif(TARGET Qt5::Core)
        set(QT_VERSION_MAJOR 5)
    else()
        set(QT_VERSION_MAJOR 5)
    endif()
    message(STATUS "  Qt version: ${QT_VERSION_MAJOR}")

    # Check if config template exists
    set(CONFIG_TEMPLATE_FILE "${CMAKE_CURRENT_SOURCE_DIR}/cmake/CloudCompareConfig.cmake.in")
    if(NOT EXISTS "${CONFIG_TEMPLATE_FILE}")
        message(WARNING "CloudCompareConfig.cmake.in not found at ${CONFIG_TEMPLATE_FILE}")
        message(WARNING "Please create this file to enable CMake package configuration")
        return()
    endif()

    # Configure the Config file
    configure_package_config_file(
        "${CONFIG_TEMPLATE_FILE}"
        "${CMAKE_CURRENT_BINARY_DIR}/cmake/CloudCompareConfig.cmake"
        INSTALL_DESTINATION "${CLOUDCOMPARE_CONFIG_INSTALL_DIR}"
        PATH_VARS
            CLOUDCOMPARE_INCLUDE_INSTALL_DIR
            CLOUDCOMPARE_LIB_INSTALL_DIR
            CLOUDCOMPARE_PLUGIN_INSTALL_DIR
    )

    # Generate version config file
    write_basic_package_version_file(
        "${CMAKE_CURRENT_BINARY_DIR}/cmake/CloudCompareConfigVersion.cmake"
        VERSION "${CC_PKG_VERSION}"
        COMPATIBILITY "${CC_PKG_COMPATIBILITY}"
    )

    # Install config files
    install(
        FILES
            "${CMAKE_CURRENT_BINARY_DIR}/cmake/CloudCompareConfig.cmake"
            "${CMAKE_CURRENT_BINARY_DIR}/cmake/CloudCompareConfigVersion.cmake"
        DESTINATION "${CLOUDCOMPARE_CONFIG_INSTALL_DIR}"
        COMPONENT Development
    )

    # Export targets for installation
    if(CLOUDCOMPARE_EXPORT_TARGETS)
        message(STATUS "  Export targets: ${CLOUDCOMPARE_EXPORT_TARGETS}")
        
        install(
            EXPORT CloudCompareTargets
            FILE CloudCompareTargets.cmake
            NAMESPACE CloudCompare::
            DESTINATION "${CLOUDCOMPARE_CONFIG_INSTALL_DIR}"
            COMPONENT Development
        )

        # Export targets for build tree usage
        export(
            EXPORT CloudCompareTargets
            FILE "${CMAKE_CURRENT_BINARY_DIR}/cmake/CloudCompareTargets.cmake"
            NAMESPACE CloudCompare::
        )
    else()
        message(WARNING "  No targets marked for export. Use EXPORT option with InstallSharedLibrary.")
    endif()

    # Register package in CMake registry if requested
    if(CLOUDCOMPARE_REGISTER_PACKAGE)
        export(PACKAGE CloudCompare)
        message(STATUS "  Registered in CMake package registry")
    endif()

    message(STATUS "=================================================")
    message(STATUS "")
endfunction()

# =============================================================================
# Internal Functions
# =============================================================================

# _InstallSharedTarget - Internal function to install shared library targets
function(_InstallSharedTarget)
    cmake_parse_arguments(
        INSTALL_SHARED_TARGET
        "EXPORT"
        "DEST_FOLDER;DEST_PATH;TARGET"
        ""
        ${ARGN}
    )
    
    # For readability
    set(shared_target "${INSTALL_SHARED_TARGET_TARGET}")
    set(full_path "${INSTALL_SHARED_TARGET_DEST_PATH}/${INSTALL_SHARED_TARGET_DEST_FOLDER}")
    
    # Determine if we should add to export set
    set(export_arg "")
    if(INSTALL_SHARED_TARGET_EXPORT AND CLOUDCOMPARE_INSTALL_CMAKE_CONFIG)
        set(export_arg "EXPORT CloudCompareTargets")
    endif()
    
    # Before CMake 3.13, install(TARGETS) would only accept targets created in the same directory scope
    if(${CMAKE_VERSION} VERSION_LESS "3.13.0")
        # Basic hack for older CMake versions
        if(APPLE OR UNIX)
            set(lib_prefix "lib")
        endif()
        
        if(CMAKE_BUILD_TYPE STREQUAL "Debug")
            get_target_property(lib_postfix ${shared_target} DEBUG_POSTFIX)
        endif()
        
        get_target_property(target_bin_dir ${shared_target} BINARY_DIR)
        set(target_shared_lib "${target_bin_dir}/${lib_prefix}${shared_target}${lib_postfix}${CMAKE_SHARED_LIBRARY_SUFFIX}")
        copy_files("${target_shared_lib}" "${full_path}" 1)
        
        # Note: Export not supported for CMake < 3.13
        if(INSTALL_SHARED_TARGET_EXPORT)
            message(WARNING "EXPORT not supported for CMake < 3.13. Target ${shared_target} will not be exported.")
        endif()
    else()
        if(WIN32)
            if(NOT CMAKE_CONFIGURATION_TYPES)
                install(
                    TARGETS ${shared_target}
                    ${export_arg}
                    RUNTIME DESTINATION ${full_path}
                        COMPONENT Runtime
                    LIBRARY DESTINATION ${full_path}
                        COMPONENT Runtime
                    ARCHIVE DESTINATION ${full_path}
                        COMPONENT Development
                )
            else()
                # Multi-config generator (Visual Studio)
                install(
                    TARGETS ${shared_target}
                    ${export_arg}
                    CONFIGURATIONS Debug
                    RUNTIME DESTINATION ${INSTALL_SHARED_TARGET_DEST_PATH}_debug/${INSTALL_SHARED_TARGET_DEST_FOLDER}
                        COMPONENT Runtime
                    LIBRARY DESTINATION ${INSTALL_SHARED_TARGET_DEST_PATH}_debug/${INSTALL_SHARED_TARGET_DEST_FOLDER}
                        COMPONENT Runtime
                    ARCHIVE DESTINATION ${INSTALL_SHARED_TARGET_DEST_PATH}_debug/${INSTALL_SHARED_TARGET_DEST_FOLDER}
                        COMPONENT Development
                )
            
                install(
                    TARGETS ${shared_target}
                    CONFIGURATIONS Release
                    RUNTIME DESTINATION ${full_path}
                        COMPONENT Runtime
                    LIBRARY DESTINATION ${full_path}
                        COMPONENT Runtime
                    ARCHIVE DESTINATION ${full_path}
                        COMPONENT Development
                )
            
                install(
                    TARGETS ${shared_target}
                    CONFIGURATIONS RelWithDebInfo
                    RUNTIME DESTINATION ${INSTALL_SHARED_TARGET_DEST_PATH}_withDebInfo/${INSTALL_SHARED_TARGET_DEST_FOLDER}
                        COMPONENT Runtime
                    LIBRARY DESTINATION ${INSTALL_SHARED_TARGET_DEST_PATH}_withDebInfo/${INSTALL_SHARED_TARGET_DEST_FOLDER}
                        COMPONENT Runtime
                    ARCHIVE DESTINATION ${INSTALL_SHARED_TARGET_DEST_PATH}_withDebInfo/${INSTALL_SHARED_TARGET_DEST_FOLDER}
                        COMPONENT Development
                )
            endif()
        else()
            # Unix/Linux/macOS
            install(
                TARGETS ${shared_target}
                ${export_arg}
                LIBRARY DESTINATION ${full_path}
                    COMPONENT Runtime
                    NAMELINK_COMPONENT Development
                ARCHIVE DESTINATION ${full_path}
                    COMPONENT Development
                RUNTIME DESTINATION ${full_path}
                    COMPONENT Runtime
                INCLUDES DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/cloudcompare/${shared_target}"
            )
        endif()
    endif()
endfunction()

# _InstallLibraryHeaders - Internal function to install library headers
function(_InstallLibraryHeaders)
    cmake_parse_arguments(
        INSTALL_LIB_HEADERS
        ""
        "TARGET;HEADERS_DIR;HEADERS_DEST"
        "HEADERS"
        ${ARGN}
    )

    # Determine destination
    if(INSTALL_LIB_HEADERS_HEADERS_DEST)
        set(dest "${CMAKE_INSTALL_INCLUDEDIR}/cloudcompare/${INSTALL_LIB_HEADERS_HEADERS_DEST}")
    elseif(INSTALL_LIB_HEADERS_TARGET)
        set(dest "${CMAKE_INSTALL_INCLUDEDIR}/cloudcompare/${INSTALL_LIB_HEADERS_TARGET}")
    else()
        set(dest "${CMAKE_INSTALL_INCLUDEDIR}/cloudcompare")
    endif()

    # Install individual header files
    if(INSTALL_LIB_HEADERS_HEADERS)
        install(
            FILES ${INSTALL_LIB_HEADERS_HEADERS}
            DESTINATION "${dest}"
            COMPONENT Development
        )
    endif()

    # Install headers from directory
    if(INSTALL_LIB_HEADERS_HEADERS_DIR AND EXISTS "${INSTALL_LIB_HEADERS_HEADERS_DIR}")
        install(
            DIRECTORY "${INSTALL_LIB_HEADERS_HEADERS_DIR}/"
            DESTINATION "${dest}"
            COMPONENT Development
            FILES_MATCHING 
                PATTERN "*.h"
                PATTERN "*.hpp"
                PATTERN "*.hxx"
                PATTERN "*.inl"
            PATTERN "private" EXCLUDE
            PATTERN "internal" EXCLUDE
        )
    endif()
endfunction()

# _InstallFiles - Internal function to install files
function(_InstallFiles)
    cmake_parse_arguments(
        INSTALL_FILES
        ""
        "DEST_FOLDER;DEST_PATH"
        "FILES"
        ${ARGN}
    )

    # For readability
    set(files "${INSTALL_FILES_FILES}")
    cmake_path(SET full_path NORMALIZE "${INSTALL_FILES_DEST_PATH}/${INSTALL_FILES_DEST_FOLDER}")

    if(WIN32)
        if(NOT CMAKE_CONFIGURATION_TYPES)
            install(
                FILES ${files}
                DESTINATION "${full_path}"
            )
        else()
            install(
                FILES ${files}
                CONFIGURATIONS Debug
                DESTINATION "${INSTALL_FILES_DEST_PATH}_debug/${INSTALL_FILES_DEST_FOLDER}"
            )
        
            install(
                FILES ${files}
                CONFIGURATIONS Release
                DESTINATION "${full_path}"
            )
        
            install(
                FILES ${files}
                CONFIGURATIONS RelWithDebInfo
                DESTINATION "${INSTALL_FILES_DEST_PATH}_withDebInfo/${INSTALL_FILES_DEST_FOLDER}"
            )
        endif()            
    else()
        install(
            FILES ${files}
            DESTINATION "${full_path}"
        )
    endif()
endfunction()
