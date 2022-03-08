
OPTION (FWMACROS_VERBOSE "verbose output from fwmacros.cmake" OFF)
OPTION (USE_PRECOMPILED_HEADERS "Use precompiled headers" ON)

set(LIB_INSTALL_DIR "" CACHE PATH "Installation directory for libraries")
set(BIN_INSTALL_DIR "" CACHE PATH "Installation directory for executables")
set(INCLUDE_INSTALL_DIR "" CACHE PATH "Installation directory for header files")
set(CMAKE_INSTALL_DIR "" CACHE PATH "Installation directory for cmake files")

#-----------------------------------------------
# Make relative paths absolute (needed later on)
#-----------------------------------------------
#foreach(p LIB BIN INCLUDE CMAKE)
#  set(var ${p}_INSTALL_DIR)
#  if(NOT IS_ABSOLUTE "${${var}}")
#    set(${var} "${CMAKE_INSTALL_PREFIX}/${${var}}")
#  endif()
#endforeach()