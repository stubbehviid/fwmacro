
OPTION (USE_PRECOMPILED_HEADERS "Use precompiled headers" ON)

set(LIB_INSTALL_DIR "" CACHE PATH "Installation directory for libraries")
set(BIN_INSTALL_DIR "" CACHE PATH "Installation directory for executables")
set(INCLUDE_INSTALL_DIR "" CACHE PATH "Installation directory for header files")
set(CMAKE_INSTALL_DIR "" CACHE PATH "Installation directory for cmake files")

if(WIN32)
	set(VCPKG_ROOT_PATH "$ENV{VCPKG_ROOT}" CACHE PATH "Path to root of BOOST library distribution")
	
	if(CMAKE_SIZEOF_VOID_P EQUAL 8)
		set(VCPKG_INSTALLED_PATH "${VCPKG_ROOT_PATH}/installed/x64-windows")
	else()
		set(VCPKG_INSTALLED_PATH "${VCPKG_ROOT_PATH}/installed/x86-windows")
	endif()
	set(CMAKE_TOOLCHAIN_FILE="${VCPKG_ROOT_PATH}/scripts/buildsystems/vcpkg.cmake")
	
	
	fwmessage(STATUS "Using VCPKG installed folder: ${VCPKG_INSTALLED_PATH}")
	fwmessage(STATUS "Using VCPKG cmake toolchaion: ${CMAKE_TOOLCHAIN_FILE}")
endif()

#-----------------------------------------------
# Make relative paths absolute (needed later on)
#-----------------------------------------------
#foreach(p LIB BIN INCLUDE CMAKE)
#  set(var ${p}_INSTALL_DIR)
#  if(NOT IS_ABSOLUTE "${${var}}")
#    set(${var} "${CMAKE_INSTALL_PREFIX}/${${var}}")
#  endif()
#endforeach()