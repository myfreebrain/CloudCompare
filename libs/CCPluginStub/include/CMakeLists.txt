
target_sources( ${PROJECT_NAME}
	PRIVATE
		${CMAKE_CURRENT_LIST_DIR}/ccDefaultPluginInterface.h
		${CMAKE_CURRENT_LIST_DIR}/ccGLPluginInterface.h
		${CMAKE_CURRENT_LIST_DIR}/ccIOPluginInterface.h
		${CMAKE_CURRENT_LIST_DIR}/ccPluginInterface.h
		${CMAKE_CURRENT_LIST_DIR}/ccStdPluginInterface.h
)

#target_include_directories( ${PROJECT_NAME}
#	PUBLIC
#	    ${CMAKE_CURRENT_LIST_DIR}
#)
target_include_directories( ${PROJECT_NAME}
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/cloudcompare/${PROJECT_NAME}>
)

