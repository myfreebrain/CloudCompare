project( QCC_GL_LIB )

add_library( ${PROJECT_NAME} SHARED )

add_subdirectory( include )
add_subdirectory( src )

target_compile_definitions( ${PROJECT_NAME} PRIVATE CCGLWINDOW_LIB_BUILD )

target_link_libraries( ${PROJECT_NAME}
    PUBLIC
	    QCC_DB_LIB
        Qt6::OpenGLWidgets
    PRIVATE
        CC_FBO_LIB
)

file(GLOB QCC_GL_PUBLIC_HEADERS 
    "${CMAKE_CURRENT_SOURCE_DIR}/include/*.h"
)

InstallSharedLibrary(
    TARGET ${PROJECT_NAME}
    EXPORT
    HEADERS ${QCC_GL_PUBLIC_HEADERS}
    HEADERS_DEST "qCC_glWindow"
)