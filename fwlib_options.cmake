
OPTION (FWMACROS_VERBOSE "verbose output from fwmacros.cmake" OFF)

OPTION (BUILD_SHARED_LIB "Build fwstdlib as shared library" ON)
OPTION (BUILD_STATIC_LIB "Build fwstdlib as static library" ON)
OPTION (USE_PRECOMPILED_HEADERS "Use precompiled headers" ON)

set(LIB_INSTALL_DIR "" CACHE PATH "Installation directory for libraries")
set(BIN_INSTALL_DIR "" CACHE PATH "Installation directory for executables")
set(INCLUDE_INSTALL_DIR "" CACHE PATH "Installation directory for header files")
set(CMAKE_INSTALL_DIR "" CACHE PATH "Installation directory for cmake files")

# Check for compatibility with precompiled headers
if(BUILD_SHARED_LIB AND BUILD_STATIC_LIB)
	message(STATUS "Disabling precompiled headers since both stard and static lib enabled")
	set(USE_PRECOMPILED_HEADERS FALSE)
endif()

if(NOT BUILD_SHARED_LIB AND NOT BUILD_STATIC_LIB)
	message(WARNING "You must select either both static or shared lib version or one of them")
	message(FATAL_ERROR "Nothing will be built if both static and shared option is off")
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