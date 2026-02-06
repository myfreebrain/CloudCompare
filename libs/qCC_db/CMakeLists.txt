project( QCC_DB_LIB )

add_library( ${PROJECT_NAME} SHARED )

add_subdirectory( include )
add_subdirectory( src )

if(USE_SYSTEM_CCCORELIB)
	find_package(CCCoreLib REQUIRED)
	#set(CCCoreLib CCCoreLib::CCCoreLib)	
	target_link_libraries( ${PROJECT_NAME}
		PUBLIC
			CCCoreLib::CCCoreLib
			Qt6::Widgets
			Qt6::OpenGL
			CC_FBO_LIB
	)
else()
	add_subdirectory( extern/CCCoreLib EXCLUDE_FROM_ALL )
	target_link_libraries( ${PROJECT_NAME}
		PUBLIC
    		CCCoreLib
			Qt6::Widgets
			Qt6::OpenGL
			CC_FBO_LIB
	)
endif()

target_compile_definitions( ${PROJECT_NAME} PRIVATE QCC_DB_LIBRARY_BUILD QT_NO_KEYWORDS )

set_target_properties( ${PROJECT_NAME} PROPERTIES
	CXX_VISIBILITY_PRESET hidden
)

file(GLOB QCC_DB_PUBLIC_HEADERS 
    "${CMAKE_CURRENT_SOURCE_DIR}/include/*.h"
)

if(NOT USE_SYSTEM_CCCORELIB)
	InstallSharedLibrary( 
		TARGET CCCoreLib
		EXPORT
	)
endif()

InstallSharedLibrary(
    TARGET ${PROJECT_NAME}
    EXPORT
    HEADERS ${QCC_DB_PUBLIC_HEADERS}
    HEADERS_DEST "qCC_db"
)

include( cmake/InstallCGALDependencies.cmake )
