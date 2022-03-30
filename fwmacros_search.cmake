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
    set(oneValueArgs ID FOUND_ID LIB_NAME LIB_INCLUDE )
    set(multiValueArgs )
    cmake_parse_arguments(LL "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )    
	
	# tell what is being done
    fwmessage(STATUS "------------------------------------------------------")
    fwmessage(STATUS "locate_library (${LL_LIB_NAME})")    
    fwmessage(STATUS "------------------------------------------------------")
    fwmessage(STATUS "  PREFER_STATIC   = ${LL_PREFER_STATIC}")
    fwmessage(STATUS "  PREFER_SHARED   = ${LL_PREFER_SHARED}")
	fwmessage(STATUS "  REQUIRED        = ${LL_REQUIRED}")
    fwmessage(STATUS "  ID              = ${LL_ID}")
	fwmessage(STATUS "  FOUND_ID        = ${LL_FOUND_ID}")
    fwmessage(STATUS "  LIB_NAME        = ${LL_LIB_NAME}")
    fwmessage(STATUS "  LIB_INCLUDE     = ${LL_LIB_INCLUDE}")
    
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
	
		#define the list of input folders for the search
		if(WIN32)
			set(LL_PATHS ${CMAKE_INSTALL_PREFIX} "c:/Program Files")
		else()
			set(LL_PATHS /usr/local/lib /opt/lib /usr/lib /usr/lib/x86_64-linux-gnu ${CMAKE_INSTALL_PREFIX})
		endif()
		fwmessage(STATUS "       - PATH = ${LL_PATHS}")
		
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
			# locate release library
			set(LL_LIB_RELEASE LL_LIB_RELEASE-NOTFOUND)
			find_library(LL_LIB_RELEASE NAMES ${LL_NAMES_RELEASE} PATHS ${LL_PATHS} NO_CACHE)
		else()
			fwmessage(STATUS "Using cached location for ${LL_LIB_NAME} - release")
			set(LL_LIB_RELEASE  ${${LL_LIB_RELEASE_LABEL}})
		endif()
		
		if(NOT EXISTS ${${LL_LIB_DEBUG_LABEL}})
			fwmessage(STATUS "Searching for ${LL_LIB_NAME} - debug")
			# locate debug library
			set(LL_LIB_DEBUG LL_LIB_DEBUG-NOTFOUND)
			find_library(LL_LIB_DEBUG NAMES ${LL_NAMES_DEBUG} PATHS ${LL_PATHS} NO_CACHE)
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
	if(NOT "${LL_LIB_INCLUDE}" STREQUAL "")
	
		set(LL_INCLUDE_DIR "${${LL_LIB_NAME}_INCLUDE_DIR}")
		fwmessage(STATUS "       - existing LL_INCLUDE_DIR = ${LL_INCLUDE_DIR}")
		
		if(NOT EXISTS ${LL_INCLUDE_DIR}/${LL_LIB_INCLUDE})
		
			# Where to look for include file
			set(PATHS ${CMAKE_INSTALL_PREFIX})
			if(WIN32)
				list(APPEND PATHS "c:/Program Files")
			else()
				list(APPEND PATHS "/usr/local/include" "/usr/include" "/opt/include" "~/include")
			endif()
		
			unset(LL_INCLUDE_FILE)	
			find_file (LL_INCLUDE_FILE "${LL_LIB_INCLUDE}" PATHS ${PATHS} PATH_SUFFIXES ${LL_LIB_NAME} lib${LL_LIB_NAME} NO_CACHE)	
			fwmessage(STATUS "       - LL_INCLUDE_FILE = ${LL_INCLUDE_FILE}")
		
			if(EXISTS ${LL_INCLUDE_FILE})	
				
				# extract directory
				unset(LL_INCLUDE_DIR)
				get_filename_component(LL_INCLUDE_DIR ${LL_INCLUDE_FILE} DIRECTORY)
				fwmessage(STATUS "       - LL_INCLUDE_DIR  = ${LL_INCLUDE_DIR}")
			endif()	
		endif()

		# create cache entry for the lib include directory
		set(${LL_LIB_NAME}_INCLUDE_DIR ${LL_INCLUDE_DIR} CACHE PATH "${LL_LIB_NAME} include directory")				
		fwmessage(STATUS "LABEL = ${LL_ID}_INCLUDE_DIRS")
		
		if(NOT EXISTS ${${LL_LIB_NAME}_INCLUDE_DIR}/${LL_LIB_INCLUDE})
			if(REQUIRED)
				message(FATAL_ERROR "Could not locate ${LL_LIB_INCLUDE}")
			else()
				set(${LL_FOUND_ID} OFF)
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