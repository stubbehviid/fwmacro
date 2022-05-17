
OPTION (USE_PRECOMPILED_HEADERS "Use precompiled headers" ON)

set(LIB_INSTALL_DIR "" CACHE PATH "Installation directory for libraries")
set(BIN_INSTALL_DIR "" CACHE PATH "Installation directory for executables")
set(INCLUDE_INSTALL_DIR "" CACHE PATH "Installation directory for header files")
set(CMAKE_INSTALL_DIR "" CACHE PATH "Installation directory for cmake files")

set(VCPKG_ROOT_PATH "$ENV{VCPKG_ROOT}" CACHE PATH "Path to root of BOOST library distribution")
	
if(WIN32)
	set(OS "windows")
	if("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "AMD64")
		set(ARCH "x64")
	else()
		set(ARCH "x86")
	endif()
endif()
	
if(APPLE)
	message(STATUS "VCPKG not currently supported")
endif()
	
if(CMAKE_SYSTEM_NAME MATCHES "Linux")
	set(OS "linux")
	if("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "x86_64")
		set(ARCH "x64")
	elseif("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "x86")
		set(ARCH "x86")
	elseif("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "arm")
		set(ARCH "arm")
	elseif("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "arm64")
		set(ARCH "arm64")
	else()
		message(WARNING "Unsupported CPU architecture")
	endif()
endif()
		
set(VCPKG_INSTALLED_PATH "${VCPKG_ROOT_PATH}/installed/${ARCH}-${OS}")	
set(VCPKG_INSTALLED_STATIC_PATH "${VCPKG_ROOT_PATH}/installed/${ARCH}-${OS}-static")	
set(CMAKE_TOOLCHAIN_FILE="${VCPKG_ROOT_PATH}/scripts/buildsystems/vcpkg.cmake")
		
fwmessage(STATUS "Using VCPKG installed folder:          ${VCPKG_INSTALLED_PATH}")
fwmessage(STATUS "Using VCPKG installed folder (static): ${VCPKG_INSTALLED_STATIC_PATH}")
fwmessage(STATUS "Using VCPKG cmake toolchaion:          ${CMAKE_TOOLCHAIN_FILE}")


#-----------------------------------------------
# Make relative paths absolute (needed later on)
#-----------------------------------------------
#foreach(p LIB BIN INCLUDE CMAKE)
#  set(var ${p}_INSTALL_DIR)
#  if(NOT IS_ABSOLUTE "${${var}}")
#    set(${var} "${CMAKE_INSTALL_PREFIX}/${${var}}")
#  endif()
#endforeach()