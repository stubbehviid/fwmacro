#define library name
set(LIB_NAME ${CMAKE_PROJECT_NAME}_static)

# generate the library core name as upper case string
string(TOUPPER ${CMAKE_PROJECT_NAME} LIB_CORENAME_UPPER)
string(TOUPPER ${LIB_NAME} LIB_NAME_UPPER)

# find dependency packages
SET(PACKAGE_DEPEND_INCLUDE_DIRS)
SET(PACKAGE_DEPEND_LIBRARIES)
foreach(pck IN LISTS STATIC_DEPENDENCY_LIBS)
	message(STATUS "Locating dependency package: ${pck}")
	find_package(${pck} REQUIRED)
	SET(PACKAGE_DEPEND_INCLUDE_DIRS ${PACKAGE_DEPEND_INCLUDE_DIRS} ${${pck}_INCLUDE_DIRS})
	SET(PACKAGE_DEPEND_LIBRARIES    ${PACKAGE_DEPEND_LIBRARIES} ${${pck}_LIBRARIES})
endforeach()

message(STATUS ${DEPEND_INCLUDE_DIRS})
message(STATUS ${DEPEND_LIBRARIES})

# create the library
add_library(${LIB_NAME} STATIC ${SOURCE_FILES} ${HEADER_FILES})
	
#dependencies	
target_include_directories(${LIB_NAME} PUBLIC  ${INCLUDE_DEPENDENCY_DIRS} ${PACKAGE_DEPEND_INCLUDE_DIRS})
target_include_directories(${LIB_NAME} PRIVATE  ${PROJECT_SOURCE_DIR})
target_include_directories(${LIB_NAME} PRIVATE  ${PROJECT_BINARY_DIR})
	
message(STATUS "Depending on: ${DEPEND_LIBRARIES}")
target_link_libraries(${LIB_NAME} PUBLIC ${PACKAGE_DEPEND_LIBRARIES})
	
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
		 RUNTIME DESTINATION ${BIN_INSTALL_DIR} COMPONENT bin
		 LIBRARY DESTINATION ${LIB_INSTALL_DIR}/${CMAKE_PROJECT_NAME} COMPONENT shlib
		 ARCHIVE DESTINATION ${LIB_INSTALL_DIR}/${CMAKE_PROJECT_NAME} COMPONENT lib)		  
	
# PDB files on windows
IF(MSVC)
	install(FILES "${PROJECT_BINARY_DIR}/Debug/${LIB_NAME}d.pdb" DESTINATION ${LIB_INSTALL_DIR}/${CMAKE_PROJECT_NAME} CONFIGURATIONS Debug)
	install(FILES "${PROJECT_BINARY_DIR}/RelWithDebInfo/${LIB_NAME}.pdb" DESTINATION ${LIB_INSTALL_DIR}/${CMAKE_PROJECT_NAME} CONFIGURATIONS RelWithDebInfo)
ENDIF()	

# include files
install (FILES ${HEADER_FILES} DESTINATION ${INCLUDE_INSTALL_DIR}/${CMAKE_PROJECT_NAME})
install (FILES ${PROJECT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_config.h DESTINATION ${INCLUDE_INSTALL_DIR}/${CMAKE_PROJECT_NAME})	

# handle configuration

# Add all targets to the build-tree export set
export(TARGETS ${LIB_NAME} FILE "${PROJECT_BINARY_DIR}/${LIB_NAME}Targets.cmake")

# Export the package for use from the build-tree
# (this registers the build-tree with a global CMake-registry)
export(PACKAGE ${LIB_NAME})

# Configuration handling
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

configure_package_config_file(cmake/libConfig.cmake.in ${PROJECT_BINARY_DIR}/${LIB_NAME}Config.cmake	INSTALL_DESTINATION ${CMAKE_INSTALL_DIR}/${LIB_NAME}
	                          PATH_VARS INCLUDE_INSTALL_DIR LIB_INSTALL_DIR )

# libConfigVersion.cmake
write_basic_package_version_file( ${PROJECT_BINARY_DIR}/${LIB_NAME}ConfigVersion.cmake
								  VERSION ${CMAKE_PROJECT_VERSION_MAJOR}.${CMAKE_PROJECT_VERSION_MINOR}.${CMAKE_PROJECT_VERSION_PATCH}
								  COMPATIBILITY AnyNewerVersion )


#configure_file(cmake/libConfigVersion.cmake.in "${PROJECT_BINARY_DIR}/${LIB_NAME}ConfigVersion.cmake" @ONLY)

# Install the FooBarConfig.cmake and FooBarConfigVersion.cmake
install(FILES  	"${PROJECT_BINARY_DIR}/${LIB_NAME}Config.cmake"
				"${PROJECT_BINARY_DIR}/${LIB_NAME}ConfigVersion.cmake"
				DESTINATION "${CMAKE_INSTALL_DIR}/${LIB_NAME}" COMPONENT dev)

# Install the export set for use with the install-tree
install(EXPORT ${LIB_NAME}Targets DESTINATION "${CMAKE_INSTALL_DIR}/${LIB_NAME}" COMPONENT dev)