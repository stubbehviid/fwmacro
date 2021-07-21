# Module will handle the creation of a CUDA compatible static library
#
# The following input variables must be set:
# 
#	SOURCE_FILES			- cpp source files
#	HEADER_FILES			- h header files
#	CUDA_SOURCE_FILES		- cu cuda source files
#	CUDA_HEADER_FILES		- ch cuda header files
#	INCLUDE_DEPENDENCY_DIRS	- list of modules that should be linked (can be empty but must exist)
#	SHARED_DEPENDENCY_LIBS	- list of directories that should be included (can be empty but must exist)
#
# The following input variable can be set
#	SHARED_DEPENDENCY_LIBS_OTHER	- list of library files not part of the cmake package system
#	ADDITIONAL_SOURCE_INCLUDE_DIRS	- Additional list of include dirs needed for the project internal)

include(macros)

# make library
make_library(NAME ${CMAKE_PROJECT_NAME} TYPE SHARED SOURCE_FILES ${SOURCE_FILES} HEADER_FILES ${HEADER_FILES} 
             DEPENDENCY_PACKAGES ${SHARED_DEPENDENCY_LIBS} DEPENDENCY_LIBS ${SHARED_DEPENDENCY_LIBS_OTHER}
			 DEPENDENCY_INCLUDE_DIRS ${INCLUDE_DEPENDENCY_DIRS} INTERNAL_INCLUDE_DIRS ${ADDITIONAL_SOURCE_INCLUDE_DIRS}
			 INSTALL
			 BIN_INSTALL_DIR ${BIN_INSTALL_DIR}
			 LIB_INSTALL_DIR ${LIB_INSTALL_DIR}
			 INCLUDE_INSTALL_DIR ${INCLUDE_INSTALL_DIR}
			 CMAKE_INSTALL_DIR ${CMAKE_INSTALL_DIR}			 
			 )




