project( CCPluginAPI )

add_library( ${PROJECT_NAME} SHARED )

find_package( Qt6
	COMPONENTS
		Gui
	REQUIRED
)

add_subdirectory( include )
add_subdirectory( src )
add_subdirectory( ui )

# We only need the includes from the stub
get_target_property( STUB_INCLUDES CCPluginStub INCLUDE_DIRECTORIES )

#target_include_directories( ${PROJECT_NAME} PUBLIC "${STUB_INCLUDES}" )
target_include_directories( ${PROJECT_NAME} 
	PUBLIC
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../CCPluginStub/include>
		$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/cloudcompare/${PROJECT_NAME}>
)


target_link_libraries( ${PROJECT_NAME}
	PUBLIC
		QCC_GL_LIB
		QCC_IO_LIB
)

target_compile_definitions( ${PROJECT_NAME} PRIVATE CCPLUGIN_API_LIBRARY_BUILD )

set_target_properties( ${PROJECT_NAME} PROPERTIES
	AUTOUIC ON # FIXME Remove after everything has moved to targets and we can set it globally
	CXX_VISIBILITY_PRESET hidden
)

file(GLOB CCPLUGINAPI_PUBLIC_HEADERS 
    "${CMAKE_CURRENT_SOURCE_DIR}/include/*.h"
)

InstallSharedLibrary(
    TARGET ${PROJECT_NAME}
    EXPORT
    HEADERS ${CCPLUGINAPI_PUBLIC_HEADERS}
    HEADERS_DEST "CCPluginAPI"
)