#macro: install_executable
#       Utility macro for handling the installation of executables
#
#   NAME                    <executable name>
#   BIN_INSTALL_DIR         where to install binary executables <final destination will be <BIN_INSTALL_DIR>
#
#   Note for all path input: if the distination is empty then the default GNU standard location with be used
#                            if the specified path is relative to final output will go to <CMAKE_INSTALL_PREFIX>/<PATH>
macro(install_executable)
    # parse input
    set(options "")
    set(oneValueArgs NAME)
    set(multiValueArgs BIN_INSTALL_DIR )
    cmake_parse_arguments(IE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )    
    
	fwmessage(STATUS "------------------------------------------------------")
    fwmessage(STATUS "install_executable (${IE_NAME})")    
    fwmessage(STATUS "------------------------------------------------------")
    fwmessage(STATUS "  NAME                      = ${IE_NAME}")
    fwmessage(STATUS "  BIN_INSTALL_DIR           = ${IE_BIN_INSTALL_DIR}")
       
    # realize the apsolute path of the various installation targets
    realize_install_path(IE_BIN_INSTALL_DIR "${CMAKE_INSTALL_BINDIR}")

	# tell where we are installing the exe
    fwmessage(STATUS "BIN_INSTALL_DIR         = ${IE_BIN_INSTALL_DIR}")
    
    # Installation
    install (TARGETS ${IE_NAME} RUNTIME DESTINATION ${BIN_INSTALL_DIR} COMPONENT bin) 
	
	fwmessage(STATUS "------------------------------------------------------")
    fwmessage(STATUS "done install_executable (${IE_NAME})")    
    fwmessage(STATUS "------------------------------------------------------")
endmacro()








# macro: make_executable
#       create an executable project
#
#   NAME <executable name>                  Name of the executable to be generated
#   CXX_SOURCE_FILES                        list of c++ source files
#   CXX_HEADER_FILES                        list of c++ header files
#   PRECOMPILED_HEADER_FILES                list of include files to be used for precompiled headers (If not set CXX_HEADER_FILES will be used if precompiled headers are active)
#   DEPENDENCY_PACKAGES                     list of dependency packages (libraries with cmake config)
#   DEPENDENCY_LIBRARIES                            list of library dependencies (libraries without cmake config)
#   DEPENDENCY_INCLUDE_DIRS                 list of filters containg includefiles needed by the library
#
#   PRIVATE_INCLUDE_DIRS                    list of private include directories (include files only needed for the compilation of the executable
#   Optional language support
#       CUDA                    if set CUDA support will be enabled
#       CUDA_SOURCE_FILES       list of cuda source files
#       CUDA_HEADER_FILES       list of cuda inlcude files
#
#   Optional input:
#       INSTALL                 if set the executable will also be installed
#       BIN_INSTALL_DIR         where to install binary executables <final destination will be <BIN_INSTALL_DIR>
#       LIB_INSTALL_DIR         where to install library files <final destination will be <LIB_INSTALL_DIR>/<NAME>
#       INCLUDE_INSTALL_DIR     where to install include files <final destination will be <INCLUDE_INSTALL_DIR>/<NAME>
#       CMAKE_INSTALL_DIR       where to install cmake config files <final destination will be <CMAKE_INSTALL_DIR>/<NAME>
#
#       Note for all path input: if the distinations are empty then the default GNU standard location with be used
#                            if the specified path is relative then the final output will go to <CMAKE_INSTALL_PREFIX>/<PATH>
macro(make_executable)
    set(options "INSTALL" "CUDA")
    set(oneValueArgs NAME)
    set(multiValueArgs CXX_SOURCE_FILES 
                       CXX_HEADER_FILES 
                       PRECOMPILED_HEADER_FILES
                       DEPENDENCY_PACKAGES 
                       DEPENDENCY_LIBRARIES 
                       DEPENDENCY_INCLUDE_DIRS
                       PRIVATE_INCLUDE_DIRS
                       CUDA_SOURCE_FILES
                       CUDA_HEADER_FILES
                       BIN_INSTALL_DIR )
    cmake_parse_arguments(ME "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )    
        
    # tell what is being generated
    fwmessage(STATUS "------------------------------------------------------")
    fwmessage(STATUS "make_executable (${ME_NAME})")   
    fwmessage(STATUS "------------------------------------------------------")
	fwmessage(STATUS "  INSTALL                  = ${ME_INSTALL}")
	fwmessage(STATUS "  CUDA                     = ${ME_CUDA}")
	fwmessage(STATUS "  NAME                     = ${ME_NAME}")
	fwmessage(STATUS "  CXX_SOURCE_FILES         = ${ME_CXX_SOURCE_FILES}")
	fwmessage(STATUS "  CXX_HEADER_FILES         = ${ME_CXX_HEADER_FILES}")
	fwmessage(STATUS "  PRECOMPILED_HEADER_FILES = ${ME_PRECOMPILED_HEADER_FILES}")
	fwmessage(STATUS "  DEPENDENCY_PACKAGES      = ${ME_DEPENDENCY_PACKAGES}")
	fwmessage(STATUS "  DEPENDENCY_LIBRARIES     = ${ME_DEPENDENCY_LIBRARIES}")
	fwmessage(STATUS "  DEPENDENCY_INCLUDE_DIRS  = ${ME_DEPENDENCY_INCLUDE_DIRS}")
	fwmessage(STATUS "  PRIVATE_INCLUDE_DIRS     = ${ME_PRIVATE_INCLUDE_DIRS}")
	fwmessage(STATUS "  CUDA_SOURCE_FILES        = ${ME_CUDA_SOURCE_FILES}")
	fwmessage(STATUS "  CUDA_HEADER_FILES        = ${ME_CUDA_HEADER_FILES}")
	fwmessage(STATUS "  BIN_INSTALL_DIR          = ${ME_INSTALL}")
	
	# grap the exe name
    set(EXE_NAME ${ME_NAME}) 
    
	# give option for how the exe should be linked 
    OPTION (${ME_NAME}_LINK_AGAINST_STATIC "Prefer to link executable against static version of library" ON)
	
    
    # locate dependencies
    realize_package_dependencies(PREFER_STATIC ${${ME_NAME}_LINK_AGAINST_STATIC} OUTPUT_ID PACKAGE PACKAGES ${ME_DEPENDENCY_PACKAGES})
    fwmessage(STATUS "PACKAGE_INCLUDE_DIRS     = ${PACKAGE_INCLUDE_DIRS}")
    fwmessage(STATUS "PACKAGE_LIBRARIES        = ${PACKAGE_LIBRARIES}")
    
    # define project files
    set(PROJECT_SOURCE_FILES)   # initiate PROJECT_SOURCE_FILES to empty
    list(APPEND PROJECT_SOURCE_FILES ${ME_CXX_SOURCE_FILES})
    list(APPEND PROJECT_SOURCE_FILES ${ME_CXX_HEADER_FILES})

    #add cuda runtime if requested
    if(ME_CUDA)
        # configure CUDA
        include(cuda)
            
        list(APPEND PROJECT_SOURCE_FILES ${ML_CUDA_SOURCE_FILES})
        list(APPEND PROJECT_HEADER_FILES ${ML_CUDA_HEADER_FILES})    
    endif()

    # create the library
	fwmessage(STATUS "PROJECT_SOURCE_FILES     = ${PROJECT_SOURCE_FILES}")
    add_executable(${EXE_NAME} ${PROJECT_SOURCE_FILES})
    
	# set configuration
    set_target_cxx_config(TARGET ${EXE_NAME})
    
    if(ME_CUDA)
        set_target_cuda_config(TARGET ${EXE_NAME})
    endif()
	
	
    # set include and library dirs
    target_include_directories(${EXE_NAME} PRIVATE   ${PACKAGE_INCLUDE_DIRS})        	# include dirs needed for pagkages
    target_include_directories(${EXE_NAME} PRIVATE   ${ME_DEPENDENCY_INCLUDE_DIRS})   	# include dirs needed by specific non packet libraries
    target_include_directories(${EXE_NAME} PRIVATE   ${PROJECT_SOURCE_DIR})             # add project source as private
    target_include_directories(${EXE_NAME} PRIVATE   ${PROJECT_BINARY_DIR})             # add project binary as private
    target_include_directories(${EXE_NAME} PRIVATE   ${ME_PRIVATE_INCLUDE_DIRS})        # add additional private include dirs (like ./include if the project include files are not found in the root)
            
    target_link_libraries(${EXE_NAME} PRIVATE ${PACKAGE_LIBRARIES} ${ME_DEPENDENCY_LIBRARIES})  # link resolved packages and specific input list of libraries
    
    # precompiled headers
    if(USE_PRECOMPILED_HEADERS)
        if("${ME_PRECOMPILED_HEADER_FILES}" STREQUAL "")
            target_precompile_headers(${EXE_NAME} PRIVATE ${HEADER_FILES})
        else()
            target_precompile_headers(${EXE_NAME} PRIVATE ${ME_PRECOMPILED_HEADER_FILES}) 
        endif()
    endif()
        
    # set target properties
    set_target_properties(${EXE_NAME} PROPERTIES VERSION "${CMAKE_PROJECT_VERSION_MAJOR}.${CMAKE_PROJECT_VERSION_MINOR}.${CMAKE_PROJECT_VERSION_PATCH}")

    #handle installation
    if(ME_INSTALL)
        install_executable(NAME ${EXE_NAME} BIN_INSTALL_DIR ${ME_BIN_INSTALL_DIR})
    endif()    
	
	# tell what is being generated
    fwmessage(STATUS "------------------------------------------------------")
    fwmessage(STATUS "done make_executable (${EXE_NAME})")   
    fwmessage(STATUS "------------------------------------------------------")	
endmacro()