# set up destination paths

# load standard path names (std cmake module)
include(GNUInstallDirs)

# define macro for cleanly expanding a path to its fully qualified version handling default values
macro(realize_install_path _name _def)
  if(NOT IS_ABSOLUTE ${${_name}})  
	if("${${_name}}" STREQUAL "")
	  set(${_name} ${_def})
	endif()
	if("${${_name}}" STREQUAL "<default>")
	  set(${_name} ${_def})
	endif()
	if(NOT IS_ABSOLUTE ${${_name}})
	  set(${_name} "${CMAKE_INSTALL_PREFIX}/${${_name}}")
	endif()  	
  endif()
endmacro()

realize_install_path(BIN_INSTALL_DIR "${CMAKE_INSTALL_BINDIR}")
realize_install_path(LIB_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}")
realize_install_path(INCLUDE_INSTALL_DIR "${CMAKE_INSTALL_INCLUDEDIR}")
realize_install_path(CMAKE_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}/cmake")

# generate paths relevant for the current library version (will be different for statis and shared lib versions
set(MODULE_BIN_INSTALL_DIR 		"${BIN_INSTALL_DIR}")
set(MODULE_LIB_INSTALL_DIR     	"${LIB_INSTALL_DIR}/${CMAKE_PROJECT_NAME}")
set(MODULE_INCLUDE_INSTALL_DIR 	"${INCLUDE_INSTALL_DIR}/${CMAKE_PROJECT_NAME}")
set(MODULE_CMAKE_INSTALL_DIR 	"${CMAKE_INSTALL_DIR}/${LIB_NAME}")

message(STATUS "BIN_INSTALL_DIR = ${MODULE_BIN_INSTALL_DIR}")
message(STATUS "LIB_INSTALL_DIR = ${MODULE_LIB_INSTALL_DIR}")
message(STATUS "INCLUDE_INSTALL_DIR = ${MODULE_INCLUDE_INSTALL_DIR}")
message(STATUS "CMAKE_INSTALL_DIR = ${MODULE_CMAKE_INSTALL_DIR}")

# Installation
install (TARGETS ${LIB_NAME}
		 EXPORT ${LIB_NAME}Targets
		 RUNTIME DESTINATION ${MODULE_BIN_INSTALL_DIR} COMPONENT bin
		 LIBRARY DESTINATION ${MODULE_LIB_INSTALL_DIR} COMPONENT shlib
		 ARCHIVE DESTINATION ${MODULE_LIB_INSTALL_DIR} COMPONENT lib)		  
	
# PDB files on windows
IF(MSVC)
	install(FILES "${PROJECT_BINARY_DIR}/Debug/${LIB_NAME}d.pdb" 		 DESTINATION ${MODULE_LIB_INSTALL_DIR} CONFIGURATIONS Debug)
	install(FILES "${PROJECT_BINARY_DIR}/RelWithDebInfo/${LIB_NAME}.pdb" DESTINATION ${MODULE_LIB_INSTALL_DIR} CONFIGURATIONS RelWithDebInfo)
ENDIF()	

# include files
install (FILES ${HEADER_FILES} DESTINATION ${MODULE_INCLUDE_INSTALL_DIR})
install (FILES ${PROJECT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_config.h DESTINATION ${MODULE_INCLUDE_INSTALL_DIR})

# handle configuration
set(CONFIG_FILE "${LIB_NAME}Config.cmake")
set(VERSION_FILE "${LIB_NAME}ConfigVersion.cmake")
set(TARGETS_FILE "${LIB_NAME}Targets.cmake")

# Configuration handling
include(CMakePackageConfigHelpers)

# Add all targets to the build-tree export set
export(TARGETS ${LIB_NAME} FILE "${PROJECT_BINARY_DIR}/${TARGETS_FILE}")

# Export the package for use from the build-tree
# (this registers the build-tree with a global CMake-registry)
export(PACKAGE ${LIB_NAME})

# generate config file
configure_package_config_file(cmake/libConfig.cmake.in ${PROJECT_BINARY_DIR}/${CONFIG_FILE}	INSTALL_DESTINATION ${MODULE_CMAKE_INSTALL_DIR}
	                          PATH_VARS MODULE_INCLUDE_INSTALL_DIR 
										DEPENDENCY_INCLUDE_DIRS)

# libConfigVersion.cmake
write_basic_package_version_file( ${PROJECT_BINARY_DIR}/${VERSION_FILE}
								  VERSION ${CMAKE_PROJECT_VERSION_MAJOR}.${CMAKE_PROJECT_VERSION_MINOR}.${CMAKE_PROJECT_VERSION_PATCH}
								  COMPATIBILITY AnyNewerVersion )

# Install the FooBarConfig.cmake and FooBarConfigVersion.cmake
install(FILES  	"${PROJECT_BINARY_DIR}/${CONFIG_FILE}"
				"${PROJECT_BINARY_DIR}/${VERSION_FILE}"
				DESTINATION "${MODULE_CMAKE_INSTALL_DIR}" COMPONENT dev)

# Install the export set for use with the install-tree
install(EXPORT ${LIB_NAME}Targets DESTINATION "${MODULE_CMAKE_INSTALL_DIR}" COMPONENT dev)
