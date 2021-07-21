# macro: realize_package_dependencies
#		find and activate a list of dependency packages (libraries with assicuate cmake config)
#
# realize_package_dependencies(OUTPUT_NAME <name> PACKAGES <list of packages>
#
# OUTPUT_NAME  the macro with generate two variables named <OUTPUT_NAME>_INCLUDE_DIRS and <OUTPUT_NAME>_LIBRARIES
# PACKAGES     list of packages to be included
#              packages with submodules can be accessed using <package name>[<sub1>,<sub2>,...,<subN>]
#
# example realize_package_dependencies(OUTPUT_NAME LIBS PACKAGES fwstdlib Qt5[core,widgets]
macro(realize_package_dependencies)
	set(options "")
    set(oneValueArgs "OUTPUT_NAME")
    set(multiValueArgs "PACKAGES")
    cmake_parse_arguments(P "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )	

	set(${P_OUTPUT_NAME}_INCLUDE_DIRS)
	set(${P_OUTPUT_NAME}_LIBRARIES)

	foreach(pck IN LISTS P_PACKAGES)	
		string(FIND ${pck} "[" pos)
		if(pos EQUAL -1)
			find_package(${pck} REQUIRED)			
			list(APPEND ${P_OUTPUT_NAME}_INCLUDE_DIRS ${${pck}_INCLUDE_DIRS})
			list(APPEND ${P_OUTPUT_NAME}_LIBRARIES    ${${pck}_LIBRARIES})
		else()			
			string(LENGTH "${pck}" len)
			string(SUBSTRING "${pck}" 0 ${pos} CORE_PACKAGE)
			string(SUBSTRING "${pck}" ${pos}+1 ${len}  MODULES)
			string(STRIP "${MODULES}" MODULES)
			string(REGEX REPLACE "[\]\[]" "" MODULES "${MODULES}")
			string(REGEX REPLACE "[,]" ";" MODULES "${MODULES}")		
		
			find_package(${CORE_PACKAGE} COMPONENTS ${MODULES} REQUIRED)			
			foreach(sub IN LISTS MODULES)		
				list(APPEND ${P_OUTPUT_NAME}_INCLUDE_DIRS ${${CORE_PACKAGE}${sub}_INCLUDE_DIRS})
				list(APPEND ${P_OUTPUT_NAME}_LIBRARIES    ${${CORE_PACKAGE}${sub}_LIBRARIES})				
			endforeach()
		endif()			
	endforeach()
	
	list(REMOVE_DUPLICATES ${P_OUTPUT_NAME}_INCLUDE_DIRS)
	list(REMOVE_DUPLICATES ${P_OUTPUT_NAME}_LIBRARIES)	
endmacro()

# macro: realize_install_path
#		utility macro for converting a path to a fully qualified path relative to the install prefix
#
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

# macro: install_retain_dir_exclude_include
#		utility macro for handlig installation of include files
#
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

#macro: install_library
#		Utility macro for handling the installation of libraries
#
#	NAME 					<library name>
#	TYPE					<library type   STATIC or SHARED>
#	HEADER_FILES			<list of c++ header files to be installed>
#	DEPENDENCY_INCLUDE_DIRS	<list of dependenct include directories that shoudl be included in the cmake config>
#	BIN_INSTALL_DIR			where to install binary executables <final destination will be <BIN_INSTALL_DIR>
#	LIB_INSTALL_DIR 		where to install library files <final destination will be <LIB_INSTALL_DIR>/<NAME>
#	INCLUDE_INSTALL_DIR 	where to install include files <final destination will be <INCLUDE_INSTALL_DIR>/<NAME>
#	CMAKE_INSTALL_DIR		where to install cmake config files <final destination will be <CMAKE_INSTALL_DIR>/<NAME>
#
#	Note for all path input: if the distination is empty then the default GNU standard location with be used
#							 if the specified path is relative to final output will go to <CMAKE_INSTALL_PREFIX>/<PATH>
macro(install_library)
	# parse input
    set(options "")
    set(oneValueArgs NAME TYPE)
    set(multiValueArgs HEADER_FILES
					   DEPENDENCY_INCLUDE_DIRS
					   BIN_INSTALL_DIR 
					   LIB_INSTALL_DIR 
					   INCLUDE_INSTALL_DIR 
					   CMAKE_INSTALL_DIR)					   
    cmake_parse_arguments(P "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )	
	
	# handle naming
	set(LIB_CORE_NAME ${P_NAME})
	if("${P_TYPE}" STREQUAL "STATIC")
		set(LIB_NAME ${P_NAME}_static)
	else()
		set(LIB_NAME ${P_NAME})
	endif()	
	
	message(STATUS "LIB_CORE_NAME = ${LIB_CORE_NAME}")
	message(STATUS "LIB_NAME      = ${LIB_NAME}")
	
	# load standard path names (std cmake module)
	include(GNUInstallDirs)
	
	# realize the apsolute path of the various installation targets
	realize_install_path(P_BIN_INSTALL_DIR "${CMAKE_INSTALL_BINDIR}")
	realize_install_path(P_LIB_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}")
	realize_install_path(P_INCLUDE_INSTALL_DIR "${CMAKE_INSTALL_INCLUDEDIR}")
	realize_install_path(P_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}/cmake")

	# generate paths relevant for the current library version (will be different for statis and shared lib versions
	set(MODULE_BIN_INSTALL_DIR 		"${P_BIN_INSTALL_DIR}")
	set(MODULE_LIB_INSTALL_DIR     	"${P_LIB_INSTALL_DIR}/${LIB_CORE_NAME}")
	set(MODULE_INCLUDE_INSTALL_DIR 	"${P_INCLUDE_INSTALL_DIR}/${LIB_CORE_NAME}")
	set(MODULE_CMAKE_INSTALL_DIR 	"${P_CMAKE_INSTALL_DIR}/${LIB_NAME}")
	set(DEPENDENCY_INCLUDE_DIRS 	 ${P_DEPENDENCY_INCLUDE_DIRS})	

	message(STATUS "BIN_INSTALL_DIR         = ${MODULE_BIN_INSTALL_DIR}")
	message(STATUS "LIB_INSTALL_DIR         = ${MODULE_LIB_INSTALL_DIR}")
	message(STATUS "INCLUDE_INSTALL_DIR     = ${MODULE_INCLUDE_INSTALL_DIR}")
	message(STATUS "CMAKE_INSTALL_DIR       = ${MODULE_CMAKE_INSTALL_DIR}")
	message(STATUS "DEPENDENCY_INCLUDE_DIRS = ${DEPENDENCY_INCLUDE_DIRS}")
	
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
	install_retain_dir_exclude_include(DESTINATION ${MODULE_INCLUDE_INSTALL_DIR} FILES ${P_HEADER_FILES})
	install (FILES ${PROJECT_BINARY_DIR}/${LIB_CORE_NAME}_config.h DESTINATION ${MODULE_INCLUDE_INSTALL_DIR})

	# handle configuration
	set(CONFIG_FILE "${LIB_NAME}Config.cmake")
	set(VERSION_FILE "${LIB_NAME}ConfigVersion.cmake")
	set(TARGETS_FILE "${LIB_NAME}Targets.cmake")
	
	message(STATUS "generating ${CONFIG_FILE}")
	message(STATUS "generating ${VERSION_FILE}")
	message(STATUS "generating ${TARGETS_FILE}")

	# Configuration handling
	include(CMakePackageConfigHelpers)

	# Add all targets to the build-tree export set
	export(TARGETS ${LIB_NAME} FILE "${PROJECT_BINARY_DIR}/${TARGETS_FILE}")

	# Export the package for use from the build-tree
	# (this registers the build-tree with a global CMake-registry)
	export(PACKAGE ${LIB_NAME})

	# locate a template for the config file (will use libConfig.cmake.in in projetc root if existing then fall back to the global default in cmake 
	find_file(LIB_CONFIG_IN libConfig.cmake.in PATHS ${CMAKE_CURRENT_SOURCE_PATH} ${CMAKE_MODULE_PATH})
	message(STATUS "LIB_CONFIG_IN = ${LIB_CONFIG_IN}")

	# make sure that DEPENDENCY_INCLUDE_DIRS exists
	if("${DEPENDENCY_INCLUDE_DIRS}" STREQUAL "")
		set(DEPENDENCY_INCLUDE_DIRS " ")
	endif()

	# generate the cmake configuration
	configure_package_config_file(${LIB_CONFIG_IN} ${PROJECT_BINARY_DIR}/${CONFIG_FILE}	INSTALL_DESTINATION ${MODULE_CMAKE_INSTALL_DIR}
	                          PATH_VARS MODULE_INCLUDE_INSTALL_DIR DEPENDENCY_INCLUDE_DIRS)

	# lgenerate version cmake file
	write_basic_package_version_file( ${PROJECT_BINARY_DIR}/${VERSION_FILE}
								  VERSION ${CMAKE_PROJECT_VERSION_MAJOR}.${CMAKE_PROJECT_VERSION_MINOR}.${CMAKE_PROJECT_VERSION_PATCH}
								  COMPATIBILITY AnyNewerVersion )

	# Install the library config and version files
	install(FILES  	"${PROJECT_BINARY_DIR}/${CONFIG_FILE}"
					"${PROJECT_BINARY_DIR}/${VERSION_FILE}"
					DESTINATION "${MODULE_CMAKE_INSTALL_DIR}" COMPONENT dev)

	# Install the export set for use with the install-tree
	install(EXPORT ${LIB_NAME}Targets DESTINATION "${MODULE_CMAKE_INSTALL_DIR}" COMPONENT dev)	
endmacro()



# macro: make_library
#		create a library project including cmake config files
#
#	NAME <library name>
# 	TYPE <either "STATIC' or 'SHARED'
#			if "STATIC is selected the output libraru will be renamed to <NAME>_static
#	SOURCE_FILES 			<list of c++ source files>
#	HEADER_FILES			<list of c++ header files>
#	DEPENDENCY_PACKAGES		<list of dependency packages (libraries with cmake config)>
#	DEPENDENCY_LIBS			<list of library dependencies (librarus without cmake config)>
#	DEPENDENCY_INCLUDE_DIRS	<list of filters containg includefiles needed by the library>
#	INTERNAL_INCLUDE_DIRS	<list of private incluyde directories (include files only needed for the compilation of trhe lib itself)>
#
#	Optional language support
#		CUDA					if set CUDA support will be enabled
#		CUDA_SOURCE_FILES		list of cuda source files
#		CUDA_HEADER_FILES		list of cuda inlcude files
#
#	Optional input:
#		INSTALL					if set the library will also be installed
#		BIN_INSTALL_DIR			where to install binary executables <final destination will be <BIN_INSTALL_DIR>
#		LIB_INSTALL_DIR 		where to install library files <final destination will be <LIB_INSTALL_DIR>/<NAME>
#		INCLUDE_INSTALL_DIR 	where to install include files <final destination will be <INCLUDE_INSTALL_DIR>/<NAME>
#		CMAKE_INSTALL_DIR		where to install cmake config files <final destination will be <CMAKE_INSTALL_DIR>/<NAME>
#
#		Note for all path input: if the distination is empty then the default GNU standard location with be used
#							 if the specified path is relative to final output will go to <CMAKE_INSTALL_PREFIX>/<PATH>
macro(make_library)
    set(options "INSTALL" "CUDA")
    set(oneValueArgs NAME TYPE)
    set(multiValueArgs SOURCE_FILES 
					   HEADER_FILES 
					   DEPENDENCY_PACKAGES 
					   DEPENDENCY_LIBS 
					   DEPENDENCY_INCLUDE_DIRS
					   INTERNAL_INCLUDE_DIRS
					   CUDA_SOURCE_FILES
					   CUDA_HEADER_FILES
					   BIN_INSTALL_DIR
					   LIB_INSTALL_DIR
					   INCLUDE_INSTALL_DIR
					   CMAKE_INSTALL_DIR )
    cmake_parse_arguments(P "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )	

	# select STATIC or SHARED library
	if("${P_TYPE}" STREQUAL "STATIC")
		set(STATIC_LIB TRUE)
	else()
		set(STATIC_LIB FALSE)
	endif()

	#define library name
	set(LIB_CORE_NAME ${P_NAME})
	if(STATIC_LIB)
		set(LIB_NAME ${LIB_CORE_NAME}_static)
	else()
		set(LIB_NAME ${LIB_CORE_NAME})
	endif()
	
	message(STATUS "------------------------------------------------------")
	message(STATUS "Generating ${LIB_NAME} library (core:${LIB_CORE_NAME})")	
	message(STATUS "------------------------------------------------------")

	# generate the library core name as upper case string
	string(TOUPPER ${CMAKE_PROJECT_NAME} LIB_CORENAME_UPPER)
	string(TOUPPER ${LIB_NAME} LIB_NAME_UPPER)

	set(DEPENDENCY_PACKAGES ${P_DEPENDENCY_PACKAGES})
	set(DEPENDENCY_LIBS ${P_DEPENDENCY_LIBS})
	set(DEPENDENCY_INCLUDE_DIRS ${P_DEPENDENCY_INCLUDE_DIRS})
	set(INTERNAL_INCLUDE_DIRS ${P_INTERNAL_INCLUDE_DIRS})

	# locate dependencies
	realize_package_dependencies(OUTPUT_NAME PACKAGE PACKAGES ${DEPENDENCY_PACKAGES})
	
	message(STATUS "INLUDE_DIRS 	        = ${PACKAGE_INCLUDE_DIRS}")
	message(STATUS "LIBRARIES   	        = ${PACKAGE_LIBRARIES}")
	message(STATUS "DEPENDENCY_PACKAGES     = ${DEPENDENCY_PACKAGES}")
	message(STATUS "DEPENDENCY_LIBS         = ${DEPENDENCY_LIBS}")
	message(STATUS "DEPENDENCY_INCLUDE_DIRS = ${DEPENDENCY_INCLUDE_DIRS}")
	message(STATUS "INTERNAL_INCLUDE_DIRS   = ${INTERNAL_INCLUDE_DIRS}")

	# define project files
	list(APPEND PROJECT_COURCE_FILES ${P_SOURCE_FILES})
	list(APPEND PROJECT_COURCE_FILES ${P_HEADER_FILES})

	#add cuda sullrt if requested
	if(P_CUDA)
		# configure CUDA
		include(cuda)
		
		# set active CUDA flags
		if(STATIC_LIB)
			set(CMAKE_CUDA_FLAGS ${CMAKE_CUDA_FLAGS_STATIC})
			set(CUDA_LIBRARIES ${CUDA_LIBRARIES_STATIC})
		else()
			set(CMAKE_CUDA_FLAGS ${CMAKE_CUDA_FLAGS_SHARED})
			set(CUDA_LIBRARIES ${CUDA_LIBRARIES_SHARED})
		endif()
	
		list(APPEND PROJECT_COURCE_FILES ${P_CUDA_SOURCE_FILES})
		list(APPEND PROJECT_COURCE_FILES ${P_CUDA_HEADER_FILES})
	
	endif()



	# create the library
	if(STATIC_LIB)
		add_library(${LIB_NAME} STATIC ${PROJECT_COURCE_FILES})
	else()
		add_library(${LIB_NAME} SHARED ${PROJECT_COURCE_FILES})
	endif()
	
	# set include and library dirs
	target_include_directories(${LIB_NAME} PUBLIC  ${PACKAGE_INCLUDE_DIRS})			# include dirs needed for pagkages
	target_include_directories(${LIB_NAME} PUBLIC  ${DEPENDENCY_INCLUDE_DIRS})		# include dirs needed by specific non packet libraries
	target_include_directories(${LIB_NAME} PRIVATE  ${PROJECT_SOURCE_DIR})			# add project source as private
	target_include_directories(${LIB_NAME} PRIVATE  ${PROJECT_BINARY_DIR})			# add project binary as private
	target_include_directories(${LIB_NAME} PRIVATE  ${INTERNAL_INCLUDE_DIRS})		# add additional internal include dirs (like ./include if the project include files are not found in the root)
			
	target_link_libraries(${LIB_NAME} PUBLIC ${PACKAGE_LIBRARIES} ${DEPENDENCY_LIBS})
	
	# precompiled headers
	if(USE_PRECOMPILED_HEADERS)
		target_precompile_headers(${LIB_NAME} PRIVATE ${HEADER_FILES})
	endif()
	
	# compile options
	target_compile_features(${LIB_NAME} PUBLIC ${CXX_COMPILER_STANDARD})
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

	#handle installation
	if(P_INSTALL)
		install_library(NAME ${LIB_CORE_NAME} TYPE ${P_TYPE} 
					    HEADER_FILES 		${P_HEADER_FILES}
						DEPENDENCY_INCLUDE_DIRS ${DEPENDENCY_INCLUDE_DIRS}
						BIN_INSTALL_DIR 	${P_BIN_INSTALL_DIR}
					    LIB_INSTALL_DIR 	${P_LIB_INSTALL_DIR}
					    INCLUDE_INSTALL_DIR ${P_INCLUDE_INSTALL_DIR}
					    CMAKE_INSTALL_DIR	${P_CMAKE_INSTALL_DIR}
						)
	
	endif()


    
endmacro()