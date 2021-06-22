#define library name
set(LIB_NAME ${CMAKE_PROJECT_NAME}_static)

# generate the library core name as upper case string
string(TOUPPER ${CMAKE_PROJECT_NAME} LIB_CORENAME_UPPER)
string(TOUPPER ${LIB_NAME} LIB_NAME_UPPER)

# find dependency packages
foreach(pck IN SHARED_DEPENDENCY_LIBS)
	message(STATUS "Locating dependency package: ${pck}")
	find_package(${pck} REQUIRED)
endforeach()

# create the library
add_library(${LIB_NAME} STATIC ${SOURCE_FILES} ${HEADER_FILES})
	
#dependencies	
target_include_directories(${LIB_NAME} PUBLIC  ${INCLUDE_DEPENDENCY_DIRS})
target_include_directories(${LIB_NAME} PRIVATE  ${PROJECT_SOURCE_DIR})
target_include_directories(${LIB_NAME} PRIVATE  ${PROJECT_BINARY_DIR})
	
# precompiled headers
if(USE_PRECOMPILED_HEADERS)
	target_precompile_headers(${LIB_NAME} PRIVATE ${HEADER_FILES})
endif()
	
# compile options
target_compile_features(${LIB_NAME} PUBLIC cxx_std_17)
set_target_properties(${LIB_NAME} PROPERTIES POSITION_INDEPENDENT_CODE ON)
	
# set target properties
set_target_properties(${LIB_NAME} PROPERTIES VERSION "${CMAKE_PROJECT_VERSION_MAJOR}.${CMAKE_PROJECT_VERSION_MINOR}.${CMAKE_PROJECT_VERSION_PATCH}")

# append d to debug libraries
set_property(TARGET ${LIB_NAME} PROPERTY DEBUG_POSTFIX d)

# If using MSVC the set the debug database filename
IF(MSVC)
	set_property(TARGET ${LIB_NAME} PROPERTY COMPILE_PDB_NAME_DEBUG "${LIB_NAME}d")
	set_property(TARGET ${LIB_NAME} PROPERTY COMPILE_PDB_NAME_RELWITHDEBINFO "${LIB_NAME}")
ENDIF()


#installation
install (TARGETS ${LIB_NAME}
		 EXPORT ${LIB_NAME}Targets
		 RUNTIME DESTINATION ${INSTALL_BIN_DIR} COMPONENT bin
		 LIBRARY DESTINATION ${INSTALL_LIB_DIR}/${CMAKE_PROJECT_NAME} COMPONENT shlib
		 ARCHIVE DESTINATION ${INSTALL_LIB_DIR}/${CMAKE_PROJECT_NAME} COMPONENT lib)		  
	
# PDB files on windows
IF(MSVC)
	install(FILES "${CMAKE_BINARY_DIR}/Debug/${LIB_NAME}d.pdb" DESTINATION ${INSTALL_LIB_DIR}/${CMAKE_PROJECT_NAME} CONFIGURATIONS Debug)
	install(FILES "${CMAKE_BINARY_DIR}/RelWithDebInfo/${LIB_NAME}.pdb" DESTINATION ${INSTALL_LIB_DIR}/${CMAKE_PROJECT_NAME} CONFIGURATIONS RelWithDebInfo)
ENDIF()	

# include files
install (FILES ${HEADER_FILES} DESTINATION ${INSTALL_INCLUDE_DIR}/${CMAKE_PROJECT_NAME})
install (FILES ${PROJECT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_config.h DESTINATION ${INSTALL_INCLUDE_DIR}/${CMAKE_PROJECT_NAME})	

# handle configuration

# Add all targets to the build-tree export set
export(TARGETS ${LIB_NAME} FILE "${PROJECT_BINARY_DIR}/${LIB_NAME}Targets.cmake")

# Export the package for use from the build-tree
# (this registers the build-tree with a global CMake-registry)
export(PACKAGE ${LIB_NAME})

# libConfig.cmake
configure_file(cmake/libConfig.cmake.in "${PROJECT_BINARY_DIR}/${LIB_NAME}Config.cmake" @ONLY)
# libConfigVersion.cmake
configure_file(cmake/libConfigVersion.cmake.in "${PROJECT_BINARY_DIR}/${LIB_NAME}ConfigVersion.cmake" @ONLY)

# Install the FooBarConfig.cmake and FooBarConfigVersion.cmake
install(FILES  	"${PROJECT_BINARY_DIR}/${LIB_NAME}Config.cmake"
				"${PROJECT_BINARY_DIR}/${LIB_NAME}ConfigVersion.cmake"
				DESTINATION "${INSTALL_CMAKE_DIR}/${LIB_NAME}" COMPONENT dev)

# Install the export set for use with the install-tree
install(EXPORT ${LIB_NAME}Targets DESTINATION "${INSTALL_CMAKE_DIR}/${LIB_NAME}" COMPONENT dev)