
target_sources( ${PROJECT_NAME}
	PRIVATE
		${CMAKE_CURRENT_LIST_DIR}/CCAppCommon.h
		${CMAKE_CURRENT_LIST_DIR}/ccApplicationBase.h
		${CMAKE_CURRENT_LIST_DIR}/ccCameraParamEditDlg.h
		${CMAKE_CURRENT_LIST_DIR}/ccDisplaySettingsDlg.h
		${CMAKE_CURRENT_LIST_DIR}/ccOptions.h
		${CMAKE_CURRENT_LIST_DIR}/ccPickOneElementDlg.h
		${CMAKE_CURRENT_LIST_DIR}/ccPluginManager.h
		${CMAKE_CURRENT_LIST_DIR}/ccStereoModeDlg.h
		${CMAKE_CURRENT_LIST_DIR}/ccTranslationManager.h
)

#target_include_directories( ${PROJECT_NAME}
#	PUBLIC
#		${CMAKE_CURRENT_LIST_DIR}
#)
target_include_directories( ${PROJECT_NAME}
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/cloudcompare/${PROJECT_NAME}>
)
