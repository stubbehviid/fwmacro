
# macro: fwmessage
#	verbosity macro for std cmake message alllowing control of verbosity
macro(fwmessage _type _text)

	if(FWMACROS_VERBOSE)
		message(${_type} "${_text}")
	endif()	
endmacro()

# load standard path names (std cmake module)
include(GNUInstallDirs)

# load std lib options
include(fwlib_options)

# include compiler options
include(fwcompiler)




# macro: realize_package_dependencies
#		find and activate a list of dependency packages (libraries with assicuate cmake config)
#
# realize_package_dependencies(OUTPUT_ID <name> PACKAGES <list of packages>
#
# OUTPUT_ID  the macro with generate two variables named <OUTPUT_ID>_INCLUDE_DIRS and <OUTPUT_ID>_LIBRARIES
# PACKAGES     list of packages to be included
#              packages with submodules can be accessed using <package name>[<sub1>,<sub2>,...,<subN>]
#
# example realize_package_dependencies(OUTPUT_ID LIBS PACKAGES fwstdlib Qt5[core,widgets]
macro(realize_package_dependencies)
	set(options "")
    set(oneValueArgs "OUTPUT_ID")
    set(multiValueArgs "PACKAGES")
    cmake_parse_arguments(P "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )	

	set(${P_OUTPUT_ID}_INCLUDE_DIRS)
	set(${P_OUTPUT_ID}_LIBRARIES)

	foreach(pck IN LISTS P_PACKAGES)	
		string(FIND ${pck} "[" pos)
		if(pos EQUAL -1)
			find_package(${pck} REQUIRED)			
			list(APPEND ${P_OUTPUT_ID}_INCLUDE_DIRS ${${pck}_INCLUDE_DIRS})
			list(APPEND ${P_OUTPUT_ID}_LIBRARIES    ${${pck}_LIBRARIES})
		else()			
			string(LENGTH "${pck}" len)
			string(SUBSTRING "${pck}" 0 ${pos} CORE_PACKAGE)
			string(SUBSTRING "${pck}" ${pos}+1 ${len}  MODULES)
			string(STRIP "${MODULES}" MODULES)
			string(REGEX REPLACE "[\]\[]" "" MODULES "${MODULES}")
			string(REGEX REPLACE "[,]" ";" MODULES "${MODULES}")		
		
			find_package(${CORE_PACKAGE} COMPONENTS ${MODULES} REQUIRED)			
			foreach(sub IN LISTS MODULES)		
				list(APPEND ${P_OUTPUT_ID}_INCLUDE_DIRS ${${CORE_PACKAGE}${sub}_INCLUDE_DIRS})
				list(APPEND ${P_OUTPUT_ID}_LIBRARIES    ${${CORE_PACKAGE}${sub}_LIBRARIES})				
			endforeach()
		endif()			
	endforeach()
	
	list(REMOVE_DUPLICATES ${P_OUTPUT_ID}_INCLUDE_DIRS)
	list(REMOVE_DUPLICATES ${P_OUTPUT_ID}_LIBRARIES)	
	
	fwmessage(STATUS "${P_OUTPUT_ID}_INCLUDE_DIRS = ${${P_OUTPUT_ID}_INCLUDE_DIRS}")
	fwmessage(STATUS "${P_OUTPUT_ID}_LIBRARIES = ${${P_OUTPUT_ID}_LIBRARIES}")
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
		# message(STATUS "FILE:${FILE}   ->   DIR=${CAS_DESTINATION}/${DIR}")
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
	
	fwmessage(STATUS "LIB_CORE_NAME = ${LIB_CORE_NAME}")
	fwmessage(STATUS "LIB_NAME      = ${LIB_NAME}")
	
	
	
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

	fwmessage(STATUS "BIN_INSTALL_DIR         = ${MODULE_BIN_INSTALL_DIR}")
	fwmessage(STATUS "LIB_INSTALL_DIR         = ${MODULE_LIB_INSTALL_DIR}")
	fwmessage(STATUS "INCLUDE_INSTALL_DIR     = ${MODULE_INCLUDE_INSTALL_DIR}")
	fwmessage(STATUS "CMAKE_INSTALL_DIR       = ${MODULE_CMAKE_INSTALL_DIR}")
	fwmessage(STATUS "DEPENDENCY_INCLUDE_DIRS = ${DEPENDENCY_INCLUDE_DIRS}")
	
	# Installation
	install (TARGETS ${LIB_NAME}
			 EXPORT ${LIB_NAME}Targets
			 RUNTIME DESTINATION ${MODULE_BIN_INSTALL_DIR} COMPONENT bin
			 LIBRARY DESTINATION ${MODULE_LIB_INSTALL_DIR} COMPONENT shlib
			 ARCHIVE DESTINATION ${MODULE_LIB_INSTALL_DIR} COMPONENT lib)		  
	
	# PDB files on windows
	IF(MSVC)
		install(FILES "${PROJECT_BINARY_DIR}/Debug/${LIB_NAME}d.pdb" 		 DESTINATION ${MODULE_LIB_INSTALL_DIR} CONFIGURATIONS Debug)
		if("${P_TYPE}" STREQUAL "SHARED")
			# MSVC does not generated pdb files for RelWithDebInfo woth target being a static library
			install(FILES "${PROJECT_BINARY_DIR}/RelWithDebInfo/${LIB_NAME}.pdb" DESTINATION ${MODULE_LIB_INSTALL_DIR} CONFIGURATIONS RelWithDebInfo)
		endif()
	ENDIF()	

	# include files
	install_retain_dir_exclude_include(DESTINATION ${MODULE_INCLUDE_INSTALL_DIR} FILES ${P_HEADER_FILES})
	install (FILES ${PROJECT_BINARY_DIR}/${LIB_CORE_NAME}_config.h DESTINATION ${MODULE_INCLUDE_INSTALL_DIR})

	# handle configuration
	set(CONFIG_FILE "${LIB_NAME}Config.cmake")
	set(VERSION_FILE "${LIB_NAME}ConfigVersion.cmake")
	set(TARGETS_FILE "${LIB_NAME}Targets.cmake")
	
	fwmessage(STATUS "generating ${CONFIG_FILE}")
	fwmessage(STATUS "generating ${VERSION_FILE}")
	fwmessage(STATUS "generating ${TARGETS_FILE}")

	# Configuration handling
	include(CMakePackageConfigHelpers)

	# Add all targets to the build-tree export set
	export(TARGETS ${LIB_NAME} FILE "${PROJECT_BINARY_DIR}/${TARGETS_FILE}")

	# Export the package for use from the build-tree
	# (this registers the build-tree with a global CMake-registry)
	export(PACKAGE ${LIB_NAME})

	# locate a template for the config file (will use libConfig.cmake.in in projetc root if existing then fall back to the global default in cmake 
	find_file(LIB_CONFIG_IN libConfig.cmake.in PATHS ${CMAKE_CURRENT_SOURCE_PATH} ${CMAKE_MODULE_PATH})
	fwmessage(STATUS "LIB_CONFIG_IN = ${LIB_CONFIG_IN}")

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

#macro: install_executable
#		Utility macro for handling the installation of executables
#
#	NAME 					<executable name>
#	BIN_INSTALL_DIR			where to install binary executables <final destination will be <BIN_INSTALL_DIR>
#	CMAKE_INSTALL_DIR		where to install cmake config files <final destination will be <CMAKE_INSTALL_DIR>/<NAME>
#
#	Note for all path input: if the distination is empty then the default GNU standard location with be used
#							 if the specified path is relative to final output will go to <CMAKE_INSTALL_PREFIX>/<PATH>
macro(install_executable)
	# parse input
    set(options "")
    set(oneValueArgs NAME)
    set(multiValueArgs BIN_INSTALL_DIR CMAKE_INSTALL_DIR)

    cmake_parse_arguments(P "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )	
	
	fwmessage(STATUS "EXE_NAME      = ${P_NAME}")
		
	# realize the apsolute path of the various installation targets
	realize_install_path(P_BIN_INSTALL_DIR "${CMAKE_INSTALL_BINDIR}")
	realize_install_path(P_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}/cmake")

	# generate paths relevant for the current library version (will be different for statis and shared lib versions
	set(MODULE_BIN_INSTALL_DIR 		"${P_BIN_INSTALL_DIR}")
	set(MODULE_CMAKE_INSTALL_DIR 	"${P_CMAKE_INSTALL_DIR}/${LIB_NAME}")

	fwmessage(STATUS "BIN_INSTALL_DIR         = ${MODULE_BIN_INSTALL_DIR}")
	fwmessage(STATUS "CMAKE_INSTALL_DIR       = ${MODULE_CMAKE_INSTALL_DIR}")
	
	# Installation
	install (TARGETS ${P_NAME} RUNTIME DESTINATION ${MODULE_BIN_INSTALL_DIR} COMPONENT bin)	
endmacro()





# macro: make_library
#		create a library project including cmake config files
#
#	NAME <library name>						Name of the library to be generated
# 	TYPE <type>								Either "STATIC' or 'SHARED'
#											if "STATIC is selected the output libraru will be renamed to <NAME>_static
#	CXX_SOURCE_FILES 						list of c++ source files
#	CXX_HEADER_FILES						list of c++ header files
#	DEPENDENCY_PACKAGES						list of dependency packages (libraries with cmake config)
#	DEPENDENCY_LIBRARIES							list of library dependencies (librarus without cmake config)
#	DEPENDENCY_INCLUDE_DIRS					list of filters containg includefiles needed by the library
#
#	PRIVATE_INCLUDE_DIRS					list of private incluyde directories (include files only needed for the compilation of trhe lib itself)
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
    set(multiValueArgs CXX_SOURCE_FILES 
					   CXX_HEADER_FILES 
					   DEPENDENCY_PACKAGES 
					   DEPENDENCY_LIBRARIES 
					   DEPENDENCY_INCLUDE_DIRS
					   PRIVATE_INCLUDE_DIRS
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
	
	# generate uppercase version of lib names
	string(TOUPPER ${LIB_CORE_NAME} LIB_CORENAME_UPPER)
	string(TOUPPER ${LIB_NAME} 		LIB_NAME_UPPER)
	
	# tell what is being generated
	fwmessage(STATUS "------------------------------------------------------")
	fwmessage(STATUS "Generating ${LIB_NAME} library (core:${LIB_CORE_NAME})")	
	fwmessage(STATUS "------------------------------------------------------")
	
	# locate dependencies
	realize_package_dependencies(OUTPUT_ID PACKAGE PACKAGES ${P_DEPENDENCY_PACKAGES})
	
	fwmessage(STATUS "PACKAGE_INCLUDE_DIRS 	  = ${PACKAGE_INCLUDE_DIRS}")
	fwmessage(STATUS "PACKAGE_LIBRARIES   	  = ${PACKAGE_LIBRARIES}")
	fwmessage(STATUS "DEPENDENCY_PACKAGES     = ${P_DEPENDENCY_PACKAGES}")
	fwmessage(STATUS "DEPENDENCY_LIBRARIES    = ${P_DEPENDENCY_LIBRARIES}")
	fwmessage(STATUS "DEPENDENCY_INCLUDE_DIRS = ${P_DEPENDENCY_INCLUDE_DIRS}")
	fwmessage(STATUS "PRIVATE_INCLUDE_DIRS    = ${P_PRIVATE_INCLUDE_DIRS}")

	# define project files
	set(PROJECT_SOURCE_FILES)	# initiate PROJECT_SOURCE_FILES to empty
	list(APPEND PROJECT_SOURCE_FILES ${P_CXX_SOURCE_FILES})
	list(APPEND PROJECT_SOURCE_FILES ${P_CXX_HEADER_FILES})

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
	
		list(APPEND PROJECT_SOURCE_FILES ${P_CUDA_SOURCE_FILES})
		list(APPEND PROJECT_SOURCE_FILES ${P_CUDA_HEADER_FILES})
	
	endif()

	# handle project config file
	find_file(H_CONFIG_IN config.h.in PATHS ${CMAKE_CURRENT_SOURCE_PATH} ${CMAKE_MODULE_PATH})
	fwmessage(STATUS "H_CONFIG_IN = ${H_CONFIG_IN}")
	configure_file(${H_CONFIG_IN} ${PROJECT_BINARY_DIR}/${LIB_CORE_NAME}_config.h)

	# create the library
	if(STATIC_LIB)
		add_library(${LIB_NAME} STATIC ${PROJECT_SOURCE_FILES})
	else()
		add_library(${LIB_NAME} SHARED ${PROJECT_SOURCE_FILES})
	endif()
	
	# set include and library dirs
	target_include_directories(${LIB_NAME} PUBLIC  	${PACKAGE_INCLUDE_DIRS})		# include dirs needed for pagkages
	target_include_directories(${LIB_NAME} PUBLIC  	${P_DEPENDENCY_INCLUDE_DIRS})	# include dirs needed by specific non packet libraries
	target_include_directories(${LIB_NAME} PRIVATE  ${PROJECT_SOURCE_DIR})			# add project source as private
	target_include_directories(${LIB_NAME} PRIVATE  ${PROJECT_BINARY_DIR})			# add project binary as private
	target_include_directories(${LIB_NAME} PRIVATE  ${P_PRIVATE_INCLUDE_DIRS})		# add additional private include dirs (like ./include if the project include files are not found in the root)
			
	target_link_libraries(${LIB_NAME} PUBLIC ${PACKAGE_LIBRARIES} ${P_DEPENDENCY_LIBRARIES})	# link resolved packages and specific input list of libraries
	
	# precompiled headers
	if(USE_PRECOMPILED_HEADERS)
		target_precompile_headers(${LIB_NAME} PRIVATE ${HEADER_FILES})
	endif()
	
	# compile options
	target_compile_features(${LIB_NAME} PUBLIC ${CXX_COMPILER_STANDARD})
	set_target_properties(${LIB_NAME} PROPERTIES POSITION_INDEPENDENT_CODE ON)
	if(NOT STATIC_LIB)
		set_target_properties(${LIB_NAME} PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS ON)
	endif()
	
	# set target properties
	set_target_properties(${LIB_NAME} PROPERTIES VERSION "${CMAKE_PROJECT_VERSION_MAJOR}.${CMAKE_PROJECT_VERSION_MINOR}.${CMAKE_PROJECT_VERSION_PATCH}")

	# append d to debug libraries
	set_property(TARGET ${LIB_NAME} PROPERTY DEBUG_POSTFIX d)

	# If using MSVC the set the debug database filename
	IF(MSVC)
		set_property(TARGET ${LIB_NAME} PROPERTY COMPILE_PDB_NAME_DEBUG "${LIB_NAME}d")
		if(NOT STATIC_LIB)
			set_property(TARGET ${LIB_NAME} PROPERTY COMPILE_PDB_NAME_RELWITHDEBINFO "${LIB_NAME}")		# MSVC does not generate pdb files for static librarues in RELWITHDEBINFO
		endif()
	ENDIF()

	#handle installation
	if(P_INSTALL)
		install_library(NAME ${LIB_CORE_NAME} TYPE ${P_TYPE} 
					    HEADER_FILES 		${P_CXX_HEADER_FILES}
						DEPENDENCY_INCLUDE_DIRS ${DEPENDENCY_INCLUDE_DIRS}
						BIN_INSTALL_DIR 	${P_BIN_INSTALL_DIR}
					    LIB_INSTALL_DIR 	${P_LIB_INSTALL_DIR}
					    INCLUDE_INSTALL_DIR ${P_INCLUDE_INSTALL_DIR}
					    CMAKE_INSTALL_DIR	${P_CMAKE_INSTALL_DIR}
						)
	
	endif()    
endmacro()


# macro: make_executable
#		create an executable project
#
#	NAME <executable name>					Name of the executable to be generated
#	CXX_SOURCE_FILES 						list of c++ source files
#	CXX_HEADER_FILES						list of c++ header files
#	DEPENDENCY_PACKAGES						list of dependency packages (libraries with cmake config)
#	DEPENDENCY_LIBRARIES							list of library dependencies (libraries without cmake config)
#	DEPENDENCY_INCLUDE_DIRS					list of filters containg includefiles needed by the library
#
#	PRIVATE_INCLUDE_DIRS					list of private include directories (include files only needed for the compilation of the executable
#	Optional language support
#		CUDA					if set CUDA support will be enabled
#		CUDA_SOURCE_FILES		list of cuda source files
#		CUDA_HEADER_FILES		list of cuda inlcude files
#
#	Optional input:
#		INSTALL					if set the executable will also be installed
#		BIN_INSTALL_DIR			where to install binary executables <final destination will be <BIN_INSTALL_DIR>
#		LIB_INSTALL_DIR 		where to install library files <final destination will be <LIB_INSTALL_DIR>/<NAME>
#		INCLUDE_INSTALL_DIR 	where to install include files <final destination will be <INCLUDE_INSTALL_DIR>/<NAME>
#		CMAKE_INSTALL_DIR		where to install cmake config files <final destination will be <CMAKE_INSTALL_DIR>/<NAME>
#
#		Note for all path input: if the distinations are empty then the default GNU standard location with be used
#							 if the specified path is relative then the final output will go to <CMAKE_INSTALL_PREFIX>/<PATH>
macro(make_executable)
    set(options "INSTALL" "CUDA")
    set(oneValueArgs NAME)
    set(multiValueArgs CXX_SOURCE_FILES 
					   CXX_HEADER_FILES 
					   DEPENDENCY_PACKAGES 
					   DEPENDENCY_LIBRARIES 
					   DEPENDENCY_INCLUDE_DIRS
					   PRIVATE_INCLUDE_DIRS
					   CUDA_SOURCE_FILES
					   CUDA_HEADER_FILES
					   BIN_INSTALL_DIR
					   LIB_INSTALL_DIR
					   INCLUDE_INSTALL_DIR
					   CMAKE_INSTALL_DIR )
    cmake_parse_arguments(P "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )	
	
	# grap the exe name
	set(EXE_NAME ${P_NAME})	
	
	# tell what is being generated
	fwmessage(STATUS "------------------------------------------------------")
	fwmessage(STATUS "Generating ${EXE_NAME} executable")	
	fwmessage(STATUS "------------------------------------------------------")
	
	# locate dependencies
	realize_package_dependencies(OUTPUT_ID PACKAGE PACKAGES ${P_DEPENDENCY_PACKAGES})
	
	fwmessage(STATUS "CXX_SOURCE_FILES 	  	  = ${P_CXX_SOURCE_FILES}")
	fwmessage(STATUS "CXX_HEADER_FILES 	  	  = ${P_CXX_HEADER_FILES}")
	fwmessage(STATUS "PACKAGE_INCLUDE_DIRS 	  = ${PACKAGE_INCLUDE_DIRS}")
	fwmessage(STATUS "PACKAGE_LIBRARIES   	  = ${PACKAGE_LIBRARIES}")
	fwmessage(STATUS "DEPENDENCY_PACKAGES     = ${P_DEPENDENCY_PACKAGES}")
	fwmessage(STATUS "DEPENDENCY_LIBRARIES    = ${P_DEPENDENCY_LIBRARIES}")
	fwmessage(STATUS "DEPENDENCY_INCLUDE_DIRS = ${P_DEPENDENCY_INCLUDE_DIRS}")
	fwmessage(STATUS "PRIVATE_INCLUDE_DIRS    = ${P_PRIVATE_INCLUDE_DIRS}")
	if(P_CUDA)
		fwmessage(STATUS "CXX_SOURCE_FILES 	  	  = ${P_CUDA_SOURCE_FILES}")
		fwmessage(STATUS "CXX_HEADER_FILES 	  	  = ${P_CUDA_HEADER_FILES}")
	endif()

	# define project files
	set(PROJECT_SOURCE_FILES)	# initiate PROJECT_SOURCE_FILES to empty
	list(APPEND PROJECT_SOURCE_FILES ${P_CXX_SOURCE_FILES})
	list(APPEND PROJECT_SOURCE_FILES ${P_CXX_HEADER_FILES})

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
	
		list(APPEND PROJECT_SOURCE_FILES ${P_CUDA_SOURCE_FILES})
		list(APPEND PROJECT_SOURCE_FILES ${P_CUDA_HEADER_FILES})
	
	endif()

	# create the library
	fwmessage(STATUS "PROJECT_SOURCE_FILES    = ${PROJECT_SOURCE_FILES}")
	add_executable(${EXE_NAME} ${PROJECT_SOURCE_FILES})
	
	# set include and library dirs
	target_include_directories(${EXE_NAME} PUBLIC 	${PACKAGE_INCLUDE_DIRS})		# include dirs needed for pagkages
	target_include_directories(${EXE_NAME} PUBLIC  	${P_DEPENDENCY_INCLUDE_DIRS})	# include dirs needed by specific non packet libraries
	target_include_directories(${EXE_NAME} PUBLIC  ${PROJECT_SOURCE_DIR})				# add project source as private
	target_include_directories(${EXE_NAME} PUBLIC  ${PROJECT_BINARY_DIR})				# add project binary as private
	target_include_directories(${EXE_NAME} PUBLIC  ${P_PRIVATE_INCLUDE_DIRS})			# add additional private include dirs (like ./include if the project include files are not found in the root)
			
	target_link_libraries(${EXE_NAME} ${PACKAGE_LIBRARIES} ${P_DEPENDENCY_LIBRARIES})	# link resolved packages and specific input list of libraries
	
	# precompiled headers
	if(USE_PRECOMPILED_HEADERS)
		target_precompile_headers(${LIB_NAME} PUBLIC ${HEADER_FILES})
	endif()
	
	# compile options
	target_compile_features(${EXE_NAME} PUBLIC ${CXX_COMPILER_STANDARD})
	
	# set target properties
	set_target_properties(${EXE_NAME} PROPERTIES VERSION "${CMAKE_PROJECT_VERSION_MAJOR}.${CMAKE_PROJECT_VERSION_MINOR}.${CMAKE_PROJECT_VERSION_PATCH}")

	#handle installation
	if(P_INSTALL)
		install_executable(NAME ${EXE_NAME} BIN_INSTALL_DIR ${P_BIN_INSTALL_DIR} CMAKE_INSTALL_DIR	${P_CMAKE_INSTALL_DIR})
	endif()    
endmacro()

# macro: make_tests
#		create a standard unit test project
#
#	LIB_NAME <name of library for which the unit tests are made>
#	TEST_MASK <mask>						file search mask for finding test source files (typically "*_test.cpp")
#	LIBTEST_CONFIG_DIR						folder where library configuration include file is located (within parent source tree)
#	DEPENDENCY_PACKAGES						list of dependency packages (libraries with cmake config)
#	DEPENDENCY_LIBRARIES							list of library dependencies (libraries without cmake config)
#	DEPENDENCY_INCLUDE_DIRS					list of filters containg includefiles needed by the library
#
#	PRIVATE_INCLUDE_DIRS					list of private include directories (include files only needed for the compilation of the executable
#	Optional language support
#		CUDA					if set CUDA support will be enabled

#
macro(make_tests)

set(options "CUDA")
    set(oneValueArgs LIB_NAME TEST_MASK LIBTEST_CONFIG_DIR)
    set(multiValueArgs DEPENDENCY_PACKAGES 
					   DEPENDENCY_LIBRARIES 
					   DEPENDENCY_INCLUDE_DIRS
					   PRIVATE_INCLUDE_DIRS
					   CUDA_SOURCE_FILES
					   CUDA_HEADER_FILES )
    cmake_parse_arguments(P "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )	

	# tell what is being generated
	fwmessage(STATUS "------------------------------------------------------")
	fwmessage(STATUS "Generating tests for ${P_LIB_NAME}")	
	fwmessage(STATUS "------------------------------------------------------")

	# enable testing 
	enable_testing ()

	OPTION (USE_EXTERNAL_CATCH2_INSTALL "If set use an external version of the catch2 test environment" ON)

	# determine static vs shared linking
	# options
	if(BUILD_STATIC_LIB AND BUILD_SHARED_LIB)
		OPTION (LINK_TESTS_AGINAST_STATIC "Lisk test unit tests against the static version of ${P_LIB_NAME}" ON)
	else()
		if(BUILD_STATIC_LIB)
			set(LINK_TESTS_AGINAST_STATIC ON)
		else()
			set(LINK_TESTS_AGINAST_STATIC OFF)
		endif()
	endif()

	# determine which library to link against
	if(LINK_TESTS_AGINAST_STATIC)
		set(LIB_NAME ${P_LIB_NAME}_static)
	else()
		set(LIB_NAME ${P_LIB_NAME})
	endif()
	message(STATUS "linking tests against: ${LIB_NAME}")

	# handle defaults for TEST_MASK
	if("${P_TEST_MASK}" STREQUAL "")
		set(P_TEST_MASK "*_test.cpp")
	endif()
	fwmessage(STATUS "Searching for tests using file mask    = ${P_TEST_MASK}")

	# handle linkage of catch2 test environment
	if(USE_EXTERNAL_CATCH2_INSTALL)
		find_package(Catch2 2 REQUIRED)
	else()
		# get the catch2 test environment
		Include(FetchContent)	

		# download catch2 from github
		FetchContent_Declare(Catch2
							GIT_REPOSITORY https://github.com/catchorg/Catch2.git
							GIT_TAG        v2.13.8
							)
		# make it available
		FetchContent_MakeAvailable(Catch2)
	endif()

	# find the test source files
	file(GLOB TEST_SOURCE_FILES RELATIVE  ${CMAKE_CURRENT_SOURCE_DIR} "${CMAKE_CURRENT_SOURCE_DIR}/${P_TEST_MASK}")
	fwmessage(STATUS "Found test source files    = ${TEST_SOURCE_FILES}")

	if(P_CUDA)
		make_executable(NAME tests 
						CXX_SOURCE_FILES ${TEST_SOURCE_FILES}
						DEPENDENCY_PACKAGES ${P_DEPENDENCY_PACKAGES} ${LIB_NAME} 
						DEPENDENCY_LIBRARIES ${P_DEPENDENCY_LIBRARIES}
						DEPENDENCY_INCLUDE_DIRS ${P_DEPENDENCY_INCLUDE_DIRS}
						PRIVATE_INCLUDE_DIRS ${P_PRIVATE_INCLUDE_DIRS}
						CUDA
						CUDA_SOURCE_FILES ${P_CUDA_SOURCE_FILES}
						CUDA_HEADER_FILES ${P_CUDA_HEADER_FILES}
						)
	
	else()
		make_executable(NAME tests 
						CXX_SOURCE_FILES ${TEST_SOURCE_FILES}
						DEPENDENCY_PACKAGES ${P_DEPENDENCY_PACKAGES} ${LIB_NAME}
						DEPENDENCY_LIBRARIES ${P_DEPENDENCY_LIBRARIES}
						DEPENDENCY_INCLUDE_DIRS ${P_DEPENDENCY_INCLUDE_DIRS}
						PRIVATE_INCLUDE_DIRS ${P_PRIVATE_INCLUDE_DIRS}
						)
	endif()
							
	target_include_directories(tests PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/.. ${PROJECT_BINARY_DIR} ${P_DEPENDENCY_INCLUDE_DIRS} ${P_LIBTEST_CONFIG_DIR})
	target_link_libraries(tests Catch2::Catch2)

	# work around for internal catch2 installation
	if(NOT USE_EXTERNAL_CATCH2_INSTALL)
		list(APPEND CMAKE_MODULE_PATH ${catch2_SOURCE_DIR}/extras)
	endif()
	
	include(CTest)
	include(Catch)
	catch_discover_tests(tests)
endmacro()