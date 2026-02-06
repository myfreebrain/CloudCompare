project( CC_FBO_LIB )

add_library( ${PROJECT_NAME} SHARED )

add_subdirectory( include )
add_subdirectory( src )

target_compile_definitions( ${PROJECT_NAME} PRIVATE CCFBO_LIBRARY_BUILD )

target_link_libraries( ${PROJECT_NAME}
	PUBLIC
	Qt6::OpenGL
)

target_include_directories( ${PROJECT_NAME}
    PUBLIC
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
		$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/cloudcompare/${PROJECT_NAME}>
)

file(GLOB CCFBO_PUBLIC_HEADERS 
    "${CMAKE_CURRENT_SOURCE_DIR}/include/*.h"
)

InstallSharedLibrary(
    TARGET ${PROJECT_NAME}
    EXPORT
    HEADERS ${CCFBO_PUBLIC_HEADERS}
    HEADERS_DEST "CCFbo"
)
