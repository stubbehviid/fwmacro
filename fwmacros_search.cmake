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
    set(options PREFER_STATIC PREFER_SHARED REQUIRED )
    set(oneValueArgs ID FOUND_ID LIB_NAME LIB_INCLUDE_FILE )
    set(multiValueArgs )
    cmake_parse_arguments(LL "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )    
	
	# tell what is being done
    fwmessage(STATUS "------------------------------------------------------")
    fwmessage(STATUS "locate_library (${LL_LIB_NAME})")    
    fwmessage(STATUS "------------------------------------------------------")
    fwmessage(STATUS "  PREFER_STATIC    = ${LL_PREFER_STATIC}")
    fwmessage(STATUS "  PREFER_SHARED    = ${LL_PREFER_SHARED}")
	fwmessage(STATUS "  REQUIRED         = ${LL_REQUIRED}")
    fwmessage(STATUS "  ID               = ${LL_ID}")
	fwmessage(STATUS "  FOUND_ID         = ${LL_FOUND_ID}")
    fwmessage(STATUS "  LIB_NAME         = ${LL_LIB_NAME}")
    fwmessage(STATUS "  LIB_INCLUDE_FILE = ${LL_LIB_INCLUDE_FILE}")
    
	# mark state as success
	set(${LL_FOUND_ID} ON)
	
	# search for library
	if(NOT "${LL_LIB_NAME}" STREQUAL "")
	
		# define the variable used to cache the library paths
		if(LL_PREFER_SHARED)
			set(LL_LIB_RELEASE_LABEL 	"${LL_LIB_NAME}_SHARED_LIBRARY_RELEASE")
			set(LL_LIB_DEBUG_LABEL 		"${LL_LIB_NAME}_SHARED_LIBRARY_DEBUG")
		else()
			set(LL_LIB_RELEASE_LABEL 	"${LL_LIB_NAME}_STATIC_LIBRARY_RELEASE")
			set(LL_LIB_DEBUG_LABEL 		"${LL_LIB_NAME}_STATIC_LIBRARY_DEBUG")
		endif()
			
		# define lists of search therms
		if(LL_PREFER_SHARED)
			set(LL_NAMES_RELEASE "${LL_LIB_NAME}.so"          "lib${LL_LIB_NAME}.so"  
			                     "${LL_LIB_NAME}.lib"         "lib${LL_LIB_NAME}.lib" 
								 "${LL_LIB_NAME}.a"           "lib${LL_LIB_NAME}.a" 
								 "${LL_LIB_NAME}_static.lib"  "lib${LL_LIB_NAME}_static.lib")
			set(LL_NAMES_DEBUG   "${LL_LIB_NAME}d.so"         "lib${LL_LIB_NAME}d.so"  
			                     "${LL_LIB_NAME}d.lib"        "lib${LL_LIB_NAME}d.lib" 
								 "${LL_LIB_NAME}d.a"          "lib${LL_LIB_NAME}d.a" 
								 "${LL_LIB_NAME}_staticd.lib" "lib${LL_LIB_NAME}_staticd.lib")
			
		else()
			set(LL_NAMES_RELEASE "${LL_LIB_NAME}.a"           "lib${LL_LIB_NAME}.a" 
								 "${LL_LIB_NAME}_static.lib"  "lib${LL_LIB_NAME}_static.lib"
								 "${LL_LIB_NAME}.so"          "lib${LL_LIB_NAME}.so"  
			                     "${LL_LIB_NAME}.lib"         "lib${LL_LIB_NAME}.lib" )
			set(LL_NAMES_DEBUG   "${LL_LIB_NAME}d.a"          "lib${LL_LIB_NAME}d.a" 
								 "${LL_LIB_NAME}_static.lib"  "lib${LL_LIB_NAME}_static.lib"
								 "${LL_LIB_NAME}d.so"         "lib${LL_LIB_NAME}d.so"  
			                     "${LL_LIB_NAME}d.lib"        "lib${LL_LIB_NAME}d.lib" )		
		endif()
		fwmessage(STATUS "       - LL_NAMES_RELEASE = ${LL_NAMES_RELEASE}")
		fwmessage(STATUS "       - LL_NAMES_DEBUG   = ${LL_NAMES_DEBUG}")
				
		if(NOT EXISTS ${${LL_LIB_RELEASE_LABEL}})
			fwmessage(STATUS "Searching for ${LL_LIB_NAME} - release")
		
			#define the list of input folders for the search
			if(WIN32)
				if(LL_PREFER_STATIC)
					#set(LL_SEARCH_PATHS "${VCPKG_INSTALLED_PATH}-static" "${VCPKG_INSTALLED_PATH}" ${CMAKE_INSTALL_PREFIX} "c:/Program Files")
					set(LL_SEARCH_PATHS "${VCPKG_INSTALLED_PATH}-static" ${CMAKE_INSTALL_PREFIX} "c:/Program Files")
				else()
					set(LL_SEARCH_PATHS "${VCPKG_INSTALLED_PATH}" "${VCPKG_INSTALLED_PATH}-static" ${CMAKE_INSTALL_PREFIX} "c:/Program Files")
				endif()
			else()
				set(LL_SEARCH_PATHS /usr/local/lib /opt/lib /usr/lib /usr/lib/x86_64-linux-gnu ${CMAKE_INSTALL_PREFIX})
			endif()
			fwmessage(STATUS "RELEASE_SEARCH_PATHS = ${LL_SEARCH_PATHS}")
						
			# locate release library
			set(LL_LIB_RELEASE LL_LIB_RELEASE-NOTFOUND)
			find_library(LL_LIB_RELEASE NAMES ${LL_NAMES_RELEASE} PATHS ${LL_SEARCH_PATHS} PATH_SUFFIXES lib ${LL_LIB_NAME} lib/${LL_LIB_NAME} NO_CACHE)
			fwmessage(STATUS "Release search result: ${LL_LIB_RELEASE}")
		else()
			fwmessage(STATUS "Using cached location for ${LL_LIB_NAME} - release")
			set(LL_LIB_RELEASE  ${${LL_LIB_RELEASE_LABEL}})
		endif()
		
		if(NOT EXISTS ${${LL_LIB_DEBUG_LABEL}})
			fwmessage(STATUS "Searching for ${LL_LIB_NAME} - debug")
		
			#define the list of input folders for the search
			if(WIN32)
				if(LL_PREFER_STATIC)
					#set(LL_SEARCH_PATHS "${VCPKG_INSTALLED_PATH}-static/debug" "${VCPKG_INSTALLED_PATH}/debug" "${VCPKG_INSTALLED_PATH}" "${VCPKG_INSTALLED_PATH}-static" "${CMAKE_INSTALL_PREFIX}" "c:/Program Files")
					set(LL_SEARCH_PATHS "${VCPKG_INSTALLED_PATH}-static/debug" "${VCPKG_INSTALLED_PATH}" "${VCPKG_INSTALLED_PATH}-static" "${CMAKE_INSTALL_PREFIX}" "c:/Program Files")
				else()
					set(LL_SEARCH_PATHS "${VCPKG_INSTALLED_PATH}/debug" "${VCPKG_INSTALLED_PATH}-static/debug" "${VCPKG_INSTALLED_PATH}" "${VCPKG_INSTALLED_PATH}-static" "${CMAKE_INSTALL_PREFIX}" "c:/Program Files")
				endif()
			else()
				set(LL_SEARCH_PATHS /usr/local/lib /opt/lib /usr/lib /usr/lib/x86_64-linux-gnu ${CMAKE_INSTALL_PREFIX})
			endif()
			fwmessage(STATUS "DEBUG_SEARCH_PATHS = ${LL_SEARCH_PATHS}")
		
			
			# locate debug library
			set(LL_LIB_DEBUG LL_LIB_DEBUG-NOTFOUND)
			find_library(LL_LIB_DEBUG NAMES ${LL_NAMES_DEBUG} PATHS ${LL_SEARCH_PATHS} PATH_SUFFIXES lib ${LL_LIB_NAME} lib/${LL_LIB_NAME} NO_CACHE)
			fwmessage(STATUS "Debug search result: ${LL_LIB_RELEASE}")
		else()
			fwmessage(STATUS "Using cached location for ${LL_LIB_NAME} - debug")
			set(LL_LIB_DEBUG  ${${LL_LIB_DEBUG_LABEL}})
		endif()
				
		if(NOT EXISTS ${LL_LIB_DEBUG})
			set(LL_LIB_DEBUG ${LL_LIB_RELEASE})
		endif()
		
		fwmessage(STATUS "       - LL_LIB_RELEASE = ${LL_LIB_RELEASE}")
		fwmessage(STATUS "       - LL_LIB_DEBUG   = ${LL_LIB_DEBUG}")
		
		set(${LL_LIB_RELEASE_LABEL} ${LL_LIB_RELEASE} CACHE FILEPATH "Location of ${LIB_NAME} library (release)")
		set(${LL_LIB_DEBUG_LABEL}   ${LL_LIB_DEBUG} CACHE FILEPATH "Location of ${LIB_NAME} library (debug)")
		
		fwmessage(STATUS "       - ${LL_LIB_RELEASE_LABEL} = ${${LL_LIB_RELEASE_LABEL}}")
		fwmessage(STATUS "       - ${LL_LIB_DEBUG_LABEL}   = ${${LL_LIB_DEBUG_LABEL}}")
		
		
		if(EXISTS ${${LL_LIB_RELEASE_LABEL}})
			foreach(F IN LISTS ${LL_LIB_RELEASE_LABEL})
				list(APPEND ${LL_ID}_LIBRARIES optimized)
				list(APPEND ${LL_ID}_LIBRARIES ${F})
			endforeach()	
			foreach(F IN LISTS ${LL_LIB_DEBUG_LABEL})
				list(APPEND ${LL_ID}_LIBRARIES debug)
				list(APPEND ${LL_ID}_LIBRARIES ${F})
			endforeach()			
		else()
			set(${LL_FOUND_ID} OFF)
			if(REQUIRED)
				message(FATAL_ERROR "Did not find required library ${LL_LIB_NAME}")
			endif()
		endif()		
	endif()
	
	# search for include
	if(NOT "${LL_LIB_INCLUDE_FILE}" STREQUAL "")
		fwmessage(STATUS "Start searching for ${LL_LIB_INCLUDE_FILE}")

		# define result label
		set(LL_INCLUDE_LABEL "${LL_LIB_NAME}_INCLUDE_DIR")

		fwmessage(STATUS "Check if ${LL_LIB_INCLUDE_FILE} is valid and exists in ${${LL_INCLUDE_LABEL}}")	
		if("${${LL_INCLUDE_LABEL}}" STREQUAL "" OR NOT EXISTS "${${LL_INCLUDE_LABEL}}/${LL_LIB_INCLUDE_FILE}")
			fwmessage(STATUS "does not exist - so do actual do search for file ${LL_LIB_INCLUDE_FILE}")
			
			# Where to look for include file
			set(SEARCH_PATHS )
			if(WIN32)
				list(APPEND SEARCH_PATHS "${VCPKG_INSTALLED_PATH}-static/include" "${VCPKG_INSTALLED_PATH}/include" "c:/Program Files")
			else()
				list(APPEND SEARCH_PATHS "/usr/local/include" "/usr/include" "/opt/include" "~/include")
			endif()
			list(APPEND SEARCH_PATHS ${CMAKE_INSTALL_PREFIX})
			fwmessage(STATUS "Search in ${SEARCH_PATHS}")
				
			unset(LL_FOUND_INCLUDE_FILE)	
			find_file (LL_FOUND_INCLUDE_FILE "${LL_LIB_INCLUDE_FILE}" PATHS ${SEARCH_PATHS} PATH_SUFFIXES ${LL_LIB_NAME} lib${LL_LIB_NAME} NO_CACHE)	
			fwmessage(STATUS "search result: LL_FOUND_INCLUDE_FILE = ${LL_FOUND_INCLUDE_FILE}")
		
			if(EXISTS ${LL_FOUND_INCLUDE_FILE})					
				# extract directory
				unset(LL_FOUND_INCLUDE_DIR)
				get_filename_component(LL_FOUND_INCLUDE_DIR ${LL_FOUND_INCLUDE_FILE} DIRECTORY)
				fwmessage(STATUS "Found ${LL_LIB_INCLUDE_FILE} in folder ${LL_FOUND_INCLUDE_DIR}")
			endif()	
			
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