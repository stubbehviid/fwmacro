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



macro(make_library)
    set(options "")
    set(oneValueArgs NAME TYPE)
    set(multiValueArgs SOURCE_FILES 
					   HEADER_FILES 
					   DEPENDENCY_PACKAGES 
					   DEPENDENCY_LIBS 
					   DEPENDENCY_INCLUDE_DIRS
					   INTERNAL_INCLUDE_DIRS)
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
	
	message(STATUS "-------------------------------------------")
	message(STATUS "Generating ${LIB_NAME} library")
	message(STATUS "-------------------------------------------")

	# generate the library core name as upper case string
	string(TOUPPER ${CMAKE_PROJECT_NAME} LIB_CORENAME_UPPER)
	string(TOUPPER ${LIB_NAME} LIB_NAME_UPPER)

	# locate dependencies
	realize_package_dependencies(OUTPUT_NAME PACKAGE PACKAGES ${P_DEPENDENCY_PACKAGES})
	
	message(STATUS "INLUDE_DIRS = ${PACKAGE_INCLUDE_DIRS}")
	message(STATUS "LIBRARIES   = ${PACKAGE_LIBRARIES}")
	message(STATUS "P_DEPENDENCY_LIBS   = ${P_DEPENDENCY_LIBS}")

	# create the library
	if(STATIC_LIB)
		add_library(${LIB_NAME} STATIC ${P_SOURCE_FILES} ${P_HEADER_FILES})
	else()
		add_library(${LIB_NAME} SHARED ${P_SOURCE_FILES} ${P_HEADER_FILES})
	endif()
	
	# set include and library dirs
	target_include_directories(${LIB_NAME} PUBLIC  ${PACKAGE_INCLUDE_DIRS})			# include dirs needed for pagkages
	target_include_directories(${LIB_NAME} PUBLIC  ${P_DEPENDENCY_INCLUDE_DIRS})	# include dirs needed by specific non packet libraries
	target_include_directories(${LIB_NAME} PRIVATE  ${PROJECT_SOURCE_DIR})			# add project source as private
	target_include_directories(${LIB_NAME} PRIVATE  ${PROJECT_BINARY_DIR})			# add project binary as private
	target_include_directories(${LIB_NAME} PRIVATE  ${P_INTERNAL_INCLUDE_DIRS})		# add additional internal include dirs (like ./include if the project include files are not found in the root)
			
	target_link_libraries(${LIB_NAME} PUBLIC ${PACKAGE_LIBRARIES} ${P_DEPENDENCY_LIBS})
	
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

    
endmacro()