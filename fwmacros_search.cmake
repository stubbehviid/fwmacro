macro(lib_search_location)
	set(options STATIC INITIAL_SEARCH DEBUG )
    set(oneValueArgs ID LIB_NAME ROOT_DIR)
    set(multiValueArgs )
    cmake_parse_arguments(LL "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )    
	
	# tell what is being done
    fwmessage(STATUS "------------------------------------------------------")
    fwmessage(STATUS "lib_search_location (${LL_LIB_NAME})")    
    fwmessage(STATUS "------------------------------------------------------")
	fwmessage(STATUS "  INITIAL_SEARCH   = ${LL_INITIAL_SEARCH}")
    fwmessage(STATUS "  STATIC           = ${LL_STATIC}")
	fwmessage(STATUS "  DEBUG            = ${LL_DEBUG}")    
    fwmessage(STATUS "  ID               = ${LL_ID}")
    fwmessage(STATUS "  LIB_NAME         = ${LL_LIB_NAME}")
	fwmessage(STATUS "  ROOT_DIR         = ${LL_ROOT_DIR}")	

	set(RESULT_PATH  "${LL_ID}_PATH")
	if(LL_INITIAL_SEARCH)
		fwmessage(STATUS "Initial search")		
		unset( ${RESULT_PATH} )
	else()
		fwmessage(STATUS "Normal search")
	endif()	

	if(NOT EXISTS ${${RESULT_PATH}})
		if(WIN32)
			fwmessage(STATUS "Search Windows")
			if(LL_STATIC)
			    if(LL_DEBUG)
				    set(LIB_MASKS ${LL_LIB_NAME}_staticd.lib ${LL_LIB_NAME}d.lib lib${LL_LIB_NAME}_staticd.lib lib${LL_LIB_NAME}d.lib
					              ${LL_LIB_NAME}_static.lib ${LL_LIB_NAME}.lib lib${LL_LIB_NAME}_static.lib lib${LL_LIB_NAME}.lib)
				else()
					set(LIB_MASKS ${LL_LIB_NAME}_static.lib ${LL_LIB_NAME}.lib lib${LL_LIB_NAME}_static.lib lib${LL_LIB_NAME}.lib)
				endif()
			else()
				if(LL_DEBUG)
					set(LIB_MASKS ${LL_LIB_NAME}d.lib lib${LL_LIB_NAME}d.lib
					              ${LL_LIB_NAME}.lib lib${LL_LIB_NAME}.lib)
				else()
					set(LIB_MASKS ${LL_LIB_NAME}.lib lib${LL_LIB_NAME}.lib)
				endif()
			endif()
		else()
			fwmessage(STATUS "Search Unix")
			if(LL_STATIC)
				if(LL_DEBUG)
					set(LIB_MASKS ${LL_LIB_NAME}d.a lib${LL_LIB_NAME}d.a)
				else()
					set(LIB_MASKS ${LL_LIB_NAME}.a lib${LL_LIB_NAME}.a)
				endif()
			else()
				if(LL_DEBUG)
					set(LIB_MASKS ${LL_LIB_NAME}d.so lib${LL_LIB_NAME}d.so ${LL_LIB_NAME}d.dylib lib${LL_LIB_NAME}d.dylib)
				else()
					set(LIB_MASKS ${LL_LIB_NAME}.so lib${LL_LIB_NAME}.so ${LL_LIB_NAME}.dylib lib${LL_LIB_NAME}.dylib)
				endif()
			endif()
		endif()

		fwmessage(STATUS "LIB_MASKS = ${LIB_MASKS}")

		if(NOT EXISTS ${${RESULT_PATH}})
			unset(LL_RESULT)
			foreach( F IN LISTS LIB_MASKS )
				if(NOT EXISTS ${LL_RESULT})
					if(EXISTS ${LL_ROOT_DIR}/lib/${F})
						set(LL_RESULT ${LL_ROOT_DIR}/lib/${F})
					elseif(EXISTS ${LL_ROOT_DIR}/lib/${LL_LIBNAME}/${F})
						set(LL_RESULT ${LL_ROOT_DIR}/lib/${LL_LIBNAME}/${F})
					endif()
				endif()
			endforeach()			
			fwmessage(STATUS "LL_RESULT = ${LL_RESULT}")
			set(${RESULT_PATH} ${LL_RESULT})
		endif()
	else()
		fwmessage(STATUS "Do nothing - search already successfull")
	endif()
endmacro()



#macro: install_library
#       Utility macro for handling the installation of libraries
#
#   PREFER_STATIC           If set the macro will look for static libraries before shared libraries
#   PREFER_SHARED           If set the macro will look for shared libraries before static libraries
#	REQUIRED				If set the library must exist
#         Note: only one of PREFER_STATIC and PREFER_SHARED can be specified (PREFER_STATIC take precedence)
#   ID                    	output ID  macro will generate <ID>_INCLUDE_DIRS and <ID>_LIBRARIES
#		  Note if ID variable already exists the found entries will be appended to the lists
#   FOUND_ID            	Name of a variable that will be set to ON or OFF depending is library was found
#   LIB_NAME         		name of library to be located			(if specified <ID>_LIBRARIES will be updated)	  (Optional)
#   LIB_INCLUDE         	Name of main include file to be located (if specified <ID>_INCLUDE_DIRS will be updated)  (Required)

macro(locate_library)
	# parse input
    set(options PREFER_STATIC PREFER_SHARED REQUIRED HEADER_ONLY )
    set(oneValueArgs ID FOUND_ID LIB_NAME LIB_INCLUDE_FILE )
    set(multiValueArgs )
    cmake_parse_arguments(LL "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )    
	
	# tell what is being done
    fwmessage(STATUS "------------------------------------------------------")
    fwmessage(STATUS "locate_library (${LL_LIB_NAME})")    
    fwmessage(STATUS "------------------------------------------------------")
    fwmessage(STATUS "  PREFER_STATIC    = ${LL_PREFER_STATIC}")
    fwmessage(STATUS "  PREFER_SHARED    = ${LL_PREFER_SHARED}")
	fwmessage(STATUS "  HEADER_ONLY      = ${LL_HEADER_ONLY}")
	fwmessage(STATUS "  REQUIRED         = ${LL_REQUIRED}")
    fwmessage(STATUS "  ID               = ${LL_ID}")
	fwmessage(STATUS "  FOUND_ID         = ${LL_FOUND_ID}")
    fwmessage(STATUS "  LIB_NAME         = ${LL_LIB_NAME}")
    fwmessage(STATUS "  LIB_INCLUDE_FILE = ${LL_LIB_INCLUDE_FILE}")
    
	# define the variable used to cache the library paths
	if(LL_PREFER_SHARED)
		set(LL_LIB_RELEASE_LABEL 	"${LL_LIB_NAME}_SHARED_LIBRARY_RELEASE")
		set(LL_LIB_DEBUG_LABEL 		"${LL_LIB_NAME}_SHARED_LIBRARY_DEBUG")
	else()
		set(LL_LIB_RELEASE_LABEL 	"${LL_LIB_NAME}_STATIC_LIBRARY_RELEASE")
		set(LL_LIB_DEBUG_LABEL 		"${LL_LIB_NAME}_STATIC_LIBRARY_DEBUG")
	endif()
	
	# ------------------------------------	
	# search for libraries
	# ------------------------------------	
	if(NOT LL_HEADER_ONLY)			
		if(LL_PREFER_STATIC)
			# locate release static library
			lib_search_location(INITIAL_SEARCH        STATIC ID LS LIB_NAME ${LL_LIB_NAME} ROOT_DIR "${VCPKG_INSTALLED_STATIC_PATH}")
			lib_search_location(                      STATIC ID LS LIB_NAME ${LL_LIB_NAME} ROOT_DIR "${CMAKE_INSTALL_PREFIX}")
			lib_search_location(                             ID LS LIB_NAME ${LL_LIB_NAME} ROOT_DIR "${VCPKG_INSTALLED_PATH}")
			lib_search_location(                             ID LS LIB_NAME ${LL_LIB_NAME} ROOT_DIR "${CMAKE_INSTALL_PREFIX}")
			
			# locate debug static library
			lib_search_location(INITIAL_SEARCH DEBUG  STATIC ID LSD LIB_NAME ${LL_LIB_NAME} ROOT_DIR "${VCPKG_INSTALLED_STATIC_PATH}/debug")
			lib_search_location(               DEBUG  STATIC ID LSD LIB_NAME ${LL_LIB_NAME} ROOT_DIR "${CMAKE_INSTALL_PREFIX}")
			lib_search_location(               DEBUG         ID LSD LIB_NAME ${LL_LIB_NAME} ROOT_DIR "${VCPKG_INSTALLED_PATH}/debug")			
			lib_search_location(               DEBUG         ID LSD LIB_NAME ${LL_LIB_NAME} ROOT_DIR "${CMAKE_INSTALL_PREFIX}")
		else()		
			# locate release shared library
			lib_search_location(INITIAL_SEARCH               ID LS LIB_NAME ${LL_LIB_NAME} ROOT_DIR "${VCPKG_INSTALLED_PATH}")
			lib_search_location(                             ID LS LIB_NAME ${LL_LIB_NAME} ROOT_DIR "${CMAKE_INSTALL_PREFIX}")
			lib_search_location(                      STATIC ID LS LIB_NAME ${LL_LIB_NAME} ROOT_DIR "${VCPKG_INSTALLED_STATIC_PATH}")
			lib_search_location(                      STATIC ID LS LIB_NAME ${LL_LIB_NAME} ROOT_DIR "${CMAKE_INSTALL_PREFIX}")
			
			# locate debug shared library		
			lib_search_location(INITIAL_SEARCH DEBUG         ID LSD LIB_NAME ${LL_LIB_NAME} ROOT_DIR "${VCPKG_INSTALLED_PATH}/debug")			
			lib_search_location(               DEBUG         ID LSD LIB_NAME ${LL_LIB_NAME} ROOT_DIR "${CMAKE_INSTALL_PREFIX}")
			lib_search_location(               DEBUG  STATIC ID LSD LIB_NAME ${LL_LIB_NAME} ROOT_DIR "${VCPKG_INSTALLED_STATIC_PATH}/debug")
			lib_search_location(               DEBUG  STATIC ID LSD LIB_NAME ${LL_LIB_NAME} ROOT_DIR "${CMAKE_INSTALL_PREFIX}")
		endif()
		
		fwmessage(STATUS "LS_PATH = ${LS_PATH}")
		fwmessage(STATUS "LSD_PATH = ${LSD_PATH}")
		
		
		set(${LL_LIB_RELEASE_LABEL} "${LS_PATH}" CACHE PATH "${LL_LIB_NAME} include directory" FORCE)
		set(${LL_LIB_DEBUG_LABEL}   "${LSD_PATH}" CACHE PATH "${LL_LIB_NAME} include directory" FORCE)
			
		if(EXISTS ${${LL_LIB_RELEASE_LABEL}})
			if(EXISTS ${${LL_LIB_DEBUG_LABEL}})
				list(APPEND ${LL_ID}_LIBRARIES optimized ${${LL_LIB_RELEASE_LABEL}} debug ${${LL_LIB_DEBUG_LABEL}})
			else()
				list(APPEND ${LL_ID}_LIBRARIES ${${LL_LIB_RELEASE_LABEL}})
			endif()
		else()
			message(ERROR "Could not locate: ${LL_LIB_RELEASE_LABEL}")
		endif()
		
		fwmessage(STATUS "${LL_ID}_LIBRARIES = ${${LL_ID}_LIBRARIES}")
	endif()
	
	# ------------------------------------	
	# search for include files
	# ------------------------------------	
	if(NOT "${LL_LIB_INCLUDE_FILE}" STREQUAL "")
		fwmessage(STATUS "Start searching for ${LL_LIB_INCLUDE_FILE}")

		# define result label
		set(LL_INCLUDE_LABEL "${LL_LIB_NAME}_INCLUDE_DIR")

		fwmessage(STATUS "Check if ${LL_LIB_INCLUDE_FILE} is valid and exists in ${${LL_INCLUDE_LABEL}}")	
		if("${${LL_INCLUDE_LABEL}}" STREQUAL "" OR NOT EXISTS "${${LL_INCLUDE_LABEL}}/${LL_LIB_INCLUDE_FILE}")
			fwmessage(STATUS "does not exist - so do actual do search for file ${LL_LIB_INCLUDE_FILE}")
			
			# Where to look for include file
			if(LL_PREFER_STATIC)			
				set(SEARCH_PATHS "${VCPKG_INSTALLED_PATH}-static/include" "${VCPKG_INSTALLED_PATH}/include")
			else()
				set(SEARCH_PATHS "${VCPKG_INSTALLED_PATH}/include" "${VCPKG_INSTALLED_PATH}-static/include")
			endif()
			list(APPEND SEARCH_PATHS ${CMAKE_INSTALL_PREFIX})
			if(NOT WIN32)
				list(APPEND SEARCH_PATHS "/usr/local/include" "/usr/include" "/opt/include" "~/include")
			endif()
			
			fwmessage(STATUS "Search in ${SEARCH_PATHS}")
				
			unset(LL_FOUND_INCLUDE_FILE)
			foreach(F IN LISTS SEARCH_PATHS)
				if(NOT EXISTS "${LL_FOUND_INCLUDE_DIR}/${LL_LIB_INCLUDE_FILE}")
					if(EXISTS "${F}/${LL_LIB_INCLUDE_FILE}")
						set(LL_FOUND_INCLUDE_DIR "${F}")
					elseif(EXISTS "${F}/${LL_LIB_NAME}/${LL_LIB_INCLUDE_FILE}")
						set(LL_FOUND_INCLUDE_DIR "${F}/${LL_LIB_NAME}")
					endif()
				endif()
			endforeach()
			
			fwmessage(STATUS "search result: LL_FOUND_INCLUDE_DIR = ${LL_FOUND_INCLUDE_DIR}")
					
			# create cache entry for the lib include directory			
			set(${LL_INCLUDE_LABEL} "${LL_FOUND_INCLUDE_DIR}" CACHE PATH "${LL_LIB_NAME} include directory" FORCE)
			fwmessage(STATUS "Setting ${LL_INCLUDE_LABEL} = ${${LL_INCLUDE_LABEL}}")			
			
			if(NOT EXISTS "${${LL_INCLUDE_LABEL}}/${LL_LIB_INCLUDE_FILE}")
				message(WARNING "Could not locate ${LL_LIB_INCLUDE_FILE}")
				set(${LL_FOUND_ID} OFF)
				if(REQUIRED)
					message(FATAL_ERROR "It was required!")
				endif()
			endif()
			
		endif()
			
		# appen the directory to the ID list
		list(APPEND ${LL_ID}_INCLUDE_DIRS  ${${LL_LIB_NAME}_INCLUDE_DIR})		
	endif()
	
	fwmessage(STATUS "${LL_FOUND_ID} = ${${LL_FOUND_ID}}")
	
	# clean-up
	list(REMOVE_DUPLICATES ${LL_ID}_INCLUDE_DIRS)	
	#list(REMOVE_DUPLICATES ${LL_ID}_LIBRARIES)	
endmacro()