
OPTION (BUILD_SHARED_LIB "Build fwstdlib as shared library" ON)
OPTION (BUILD_STATIC_LIB "Build fwstdlib as static library" ON)
OPTION (USE_PRECOMPILED_HEADERS "Use precompiled headers" ON)

set(INSTALL_LIB_DIR lib CACHE PATH "Installation directory for libraries")
set(INSTALL_BIN_DIR bin CACHE PATH "Installation directory for executables")
set(INSTALL_INCLUDE_DIR include CACHE PATH "Installation directory for header files")
set(INSTALL_CMAKE_DIR lib/cmake CACHE PATH "Installation directory for cmake files")

# Check for compatibility with precompiled headers
if(BUILD_SHARED_LIB AND BUILD_STATIC_LIB)
	message(STATUS "Disabling precompiled headers since both stard and static lib enabled")
	set(USE_PRECOMPILED_HEADERS FALSE)
endif()

# compiler options
include(cmake/compiler.cmake)

# Configuration handling
include(CMakePackageConfigHelpers)

if(NOT BUILD_SHARED_LIB AND NOT BUILD_STATIC_LIB)
	message(WARNING "You must select either both static or shared lib version or one of them")
	message(FATAL_ERROR "Nothing will be built if both static and shared option is off")
endif()

