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

# macro for installing files maintaining relative directory stricture Trim the first folder of the destination path 
# so if include/dir1/dir2/file.h is input the destination will be dir1/dir2)
macro(install_retain_dir_exclude_include)
    set(options "")
    set(oneValueArgs "DESTINATION")
    set(multiValueArgs "FILES")
    cmake_parse_arguments(CAS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )	

    foreach(FILE ${CAS_FILES})       	
		# set default sub path
		set(SFILE ${FILE})
	
		# split path into list
		string(REGEX REPLACE "[/\]" ";" PATH_LIST ${FILE})	# turn path into a list
		
		# check if first element in path list is "include" if so remove the node
		list(GET PATH_LIST 0 FIRST_FOLDER)
		
		if("${FIRST_FOLDER}" STREQUAL "include")
			list(POP_FRONT PATH_LIST PATH_LIST)					# remove first entry in list if number of elements in path > 1 (we do not want to delete the filename itself)
			list(JOIN PATH_LIST "/" SFILE)						# list back to path
		endif()
		get_filename_component(DIR ${SFILE} DIRECTORY)		# extract the relative sub folder to use as destination
		#message(STATUS "FILE:${FILE}   ->   DIR=${CAS_DESTINATION}/${DIR}")
        install(FILES ${FILE} DESTINATION ${CAS_DESTINATION}/${DIR})	# install the file
    endforeach()
endmacro()


realize_install_path(BIN_INSTALL_DIR "${CMAKE_INSTALL_BINDIR}")
realize_install_path(LIB_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}")
realize_install_path(INCLUDE_INSTALL_DIR "${CMAKE_INSTALL_INCLUDEDIR}")
realize_install_path(CMAKE_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}/cmake")

# generate paths relevant for the current library version (will be different for statis and shared lib versions
set(MODULE_BIN_INSTALL_DIR 		"${BIN_INSTALL_DIR}")
set(MODULE_LIB_INSTALL_DIR     	"${LIB_INSTALL_DIR}/${LIB_CORE_NAME}")
set(MODULE_INCLUDE_INSTALL_DIR 	"${INCLUDE_INSTALL_DIR}/${LIB_CORE_NAME}")
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
install_retain_dir_exclude_include(DESTINATION ${MODULE_INCLUDE_INSTALL_DIR} FILES ${HEADER_FILES})
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

# make sure that DEPENDENCY_INCLUDE_DIRS is defined
if("${DEPENDENCY_INCLUDE_DIRS}" STREQUAL "")
  set(DEPENDENCY_INCLUDE_DIRS "")
endif()

# generate config file
find_file(LIB_CONFIG_IN libConfig.cmake.in PATHS ${CMAKE_CURRENT_SOURCE_PATH} ${CMAKE_MODULE_PATH})
message(STATUS "LIB_CONFIG_IN = ${LIB_CONFIG_IN}")

configure_package_config_file(${LIB_CONFIG_IN} ${PROJECT_BINARY_DIR}/${CONFIG_FILE}	INSTALL_DESTINATION ${MODULE_CMAKE_INSTALL_DIR}
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
