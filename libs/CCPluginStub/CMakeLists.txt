project( CCPluginStub )

add_library( ${PROJECT_NAME} STATIC )

set_target_properties( ${PROJECT_NAME} PROPERTIES
    AUTOMOC OFF
    AUTORCC OFF
    AUTOUIC OFF
)

add_subdirectory( include )
add_subdirectory( src )

target_link_libraries( ${PROJECT_NAME}
	PUBLIC
		QCC_DB_LIB
)

file(GLOB CCPLUGINSTUB_PUBLIC_HEADERS 
    "${CMAKE_CURRENT_SOURCE_DIR}/include/*.h"
)

InstallSharedLibrary(
    TARGET ${PROJECT_NAME}
    EXPORT
    HEADERS ${CCPLUGINSTUB_PUBLIC_HEADERS}
    HEADERS_DEST "CCPluginStub"
)