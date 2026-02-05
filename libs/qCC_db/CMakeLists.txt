project( QCC_DB_LIB )

add_library( ${PROJECT_NAME} SHARED )

add_subdirectory( include )
add_subdirectory( src )

add_subdirectory( extern/CCCoreLib EXCLUDE_FROM_ALL )

target_link_libraries( ${PROJECT_NAME}
	PUBLIC
    	CCCoreLib
		Qt6::Widgets
		Qt6::OpenGL
		CC_FBO_LIB
)

target_compile_definitions( ${PROJECT_NAME} PRIVATE QCC_DB_LIBRARY_BUILD QT_NO_KEYWORDS )

set_target_properties( ${PROJECT_NAME} PROPERTIES
	CXX_VISIBILITY_PRESET hidden
)

file(GLOB QCC_DB_PUBLIC_HEADERS 
    "${CMAKE_CURRENT_SOURCE_DIR}/*.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/include/*.h"
)

InstallSharedLibrary( 
    TARGET CCCoreLib
    EXPORT
)
InstallSharedLibrary(
    TARGET ${PROJECT_NAME}
    EXPORT
    HEADERS ${QCC_DB_PUBLIC_HEADERS}
    HEADERS_DEST "qCC_db"
)

include( cmake/InstallCGALDependencies.cmake )
