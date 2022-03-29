#macro: install_library
#       Utility macro for handling the installation of libraries
#
#   CORE_NAME               <core library name>
#   NAME                    <library name>
#   HEADER_FILES            <list of c++ header files to be installed>
#   BIN_INSTALL_DIR         where to install binary executables <final destination will be <BIN_INSTALL_DIR>
#   LIB_INSTALL_DIR         where to install library files <final destination will be <LIB_INSTALL_DIR>/<NAME>
#   INCLUDE_INSTALL_DIR     where to install include files <final destination will be <INCLUDE_INSTALL_DIR>/<NAME>
#   CMAKE_INSTALL_DIR       where to install cmake config files <final destination will be <CMAKE_INSTALL_DIR>/<NAME>
#
#   INSTALL_PDB             if set and on WIN32 the debug PDB files will be installed

#   Note for all path input: if the distination is empty then the default GNU standard location with be used
#                            if the specified path is relative to final output will go to <CMAKE_INSTALL_PREFIX>/<PATH>
macro(install_library)
    # parse input
    set(options "INSTALL_PDB")
    set(oneValueArgs CORE_NAME NAME )
    set(multiValueArgs HEADER_FILES
                       BIN_INSTALL_DIR 
                       LIB_INSTALL_DIR 
                       INCLUDE_INSTALL_DIR 
                       CMAKE_INSTALL_DIR)
    cmake_parse_arguments(IL "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )    
    
    # tell what is being done
    fwmessage(STATUS "------------------------------------------------------")
    fwmessage(STATUS "install_library (${IL_NAME})")    
    fwmessage(STATUS "------------------------------------------------------")
    fwmessage(STATUS "  CORE_NAME                 = ${IL_CORE_NAME}")
    fwmessage(STATUS "  NAME                      = ${IL_NAME}")
    fwmessage(STATUS "  HEADER_FILES              = ${IL_HEADER_FILES}")
    fwmessage(STATUS "  BIN_INSTALL_DIR           = ${IL_BIN_INSTALL_DIR}")
    fwmessage(STATUS "  LIB_INSTALL_DIR           = ${IL_LIB_INSTALL_DIR}")
    fwmessage(STATUS "  INCLUDE_INSTALL_DIR       = ${IL_INCLUDE_INSTALL_DIR}")
    fwmessage(STATUS "  CMAKE_INSTALL_DIR         = ${IL_CMAKE_INSTALL_DIR}")
        
    # realize the apsolute path of the various installation targets
    realize_install_path(IL_BIN_INSTALL_DIR "${CMAKE_INSTALL_BINDIR}")
    realize_install_path(IL_LIB_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}")
    realize_install_path(IL_INCLUDE_INSTALL_DIR "${CMAKE_INSTALL_INCLUDEDIR}")
    realize_install_path(IL_CMAKE_INSTALL_DIR "${CMAKE_INSTALL_LIBDIR}")

    # generate paths relevant for the current library version (will be different for statis and shared lib versions
    set(MODULE_BIN_INSTALL_DIR          ${IL_BIN_INSTALL_DIR})
    set(MODULE_LIB_INSTALL_DIR          ${IL_LIB_INSTALL_DIR}/${IL_CORE_NAME})
    set(MODULE_INCLUDE_INSTALL_DIR      ${IL_INCLUDE_INSTALL_DIR}/${IL_CORE_NAME})
    set(MODULE_CMAKE_INSTALL_DIR        ${IL_CMAKE_INSTALL_DIR}/cmake/${IL_NAME})
    set(CONFIG_FILE                     ${IL_NAME}Config.cmake)
    set(VERSION_FILE                    ${IL_NAME}ConfigVersion.cmake)
    set(TARGETS_FILE                    ${IL_NAME}Targets.cmake)
        
    fwmessage(STATUS "MODULE_BIN_INSTALL_DIR         = ${MODULE_BIN_INSTALL_DIR}")
    fwmessage(STATUS "MODULE_LIB_INSTALL_DIR         = ${MODULE_LIB_INSTALL_DIR}")
    fwmessage(STATUS "MODULE_INCLUDE_INSTALL_DIR     = ${MODULE_INCLUDE_INSTALL_DIR}")
    fwmessage(STATUS "MODULE_CMAKE_INSTALL_DIR       = ${MODULE_CMAKE_INSTALL_DIR}")
    fwmessage(STATUS "CONFIG_FILE                    = ${CONFIG_FILE}")
    fwmessage(STATUS "VERSION_FILE                   = ${VERSION_FILE}")
    fwmessage(STATUS "TARGETS_FILE                   = ${TARGETS_FILE}")
                    
    # set interface include folder
    target_include_directories(${IL_NAME} INTERFACE   ${MODULE_INCLUDE_INSTALL_DIR})   

    # Installation
    install (TARGETS ${IL_NAME}
             EXPORT ${IL_NAME}Targets )              

    # PDB files on windows
    IF(MSVC AND IL_INSTALL_PDB)
        install(FILES "${PROJECT_BINARY_DIR}/Debug/${IL_NAME}d.pdb"         DESTINATION ${MODULE_LIB_INSTALL_DIR} CONFIGURATIONS Debug)
        install(FILES "${PROJECT_BINARY_DIR}/RelWithDebInfo/${IL_NAME}.pdb" DESTINATION ${MODULE_LIB_INSTALL_DIR} CONFIGURATIONS RelWithDebInfo)
    endif() 

    # include files
    install_retain_dir_exclude_include(DESTINATION ${MODULE_INCLUDE_INSTALL_DIR} FILES ${IL_HEADER_FILES})
    install (FILES ${PROJECT_BINARY_DIR}/${IL_CORE_NAME}_config.h DESTINATION ${MODULE_INCLUDE_INSTALL_DIR}) 

    # Configuration handling
    include(CMakePackageConfigHelpers)

    # set the global var LIB_NAME (used by config file expansion so it must exist!
    set(LIB_NAME ${IL_NAME})     
        
    # Add all targets to the build-tree export set
    #export(TARGETS ${IL_NAME} FILE "${PROJECT_BINARY_DIR}/${TARGETS_FILE}")  

    # Export the package for use from the build-tree
    # (this registers the build-tree with a global CMake-registry)
    #export(PACKAGE ${IL_NAME})   

    # locate a template for the config file (will use libConfig.cmake.in in projetc root if existing then fall back to the global default in cmake 
    find_file(LIB_CONFIG_IN libConfig.cmake.in PATHS ${CMAKE_CURRENT_SOURCE_PATH} ${CMAKE_MODULE_PATH})
    fwmessage(STATUS "LIB_CONFIG_IN = ${LIB_CONFIG_IN}")    

    # generate the cmake configuration
    configure_package_config_file(${LIB_CONFIG_IN} ${PROJECT_BINARY_DIR}/${CONFIG_FILE} INSTALL_DESTINATION ${MODULE_CMAKE_INSTALL_DIR}
                              PATH_VARS MODULE_INCLUDE_INSTALL_DIR) 

    # lgenerate version cmake file
    write_basic_package_version_file( ${PROJECT_BINARY_DIR}/${VERSION_FILE}
                                  VERSION ${CMAKE_PROJECT_VERSION_MAJOR}.${CMAKE_PROJECT_VERSION_MINOR}.${CMAKE_PROJECT_VERSION_PATCH}
                                  COMPATIBILITY AnyNewerVersion )   

    # Install the library config and version files
    install(FILES   "${PROJECT_BINARY_DIR}/${CONFIG_FILE}"
                    "${PROJECT_BINARY_DIR}/${VERSION_FILE}"
                    DESTINATION ${MODULE_CMAKE_INSTALL_DIR})

    # Install the export set for use with the install-tree
    install(EXPORT ${IL_NAME}Targets DESTINATION ${MODULE_CMAKE_INSTALL_DIR})  

	# Add all targets to the build-tree export set
    export(TARGETS ${IL_NAME} FILE "${PROJECT_BINARY_DIR}/${TARGETS_FILE}")  

    # Export the package for use from the build-tree
    # (this registers the build-tree with a global CMake-registry)
    export(PACKAGE ${IL_NAME})  

	fwmessage(STATUS "------------------------------------------------------")
    fwmessage(STATUS "done install_library (${IL_NAME})")    
    fwmessage(STATUS "------------------------------------------------------")	
endmacro()




# macro: make_library
#       create a library project including cmake config files
#
#   NAME <library name>                     Name of the library to be generated
#   TYPE <type>                             Either STATIC, SHARED or STATIC_AND_SHARED
#   CXX_SOURCE_FILES                        list of c++ source files
#   CXX_HEADER_FILES                        list of c++ header files
#   PRECOMPILED_HEADER_FILES                list of include files to be used for precompiled headers (If not set CXX_HEADER_FILES will be used if precompiled headers are active)
#   DEPENDENCY_PACKAGES                     list of dependency packages (libraries with cmake config)
#   DEPENDENCY_LIBRARIES                    list of library dependencies (librarus without cmake config) - relevant for both STATIC and SHARED
#   STATIC_DEPENDENCY_LIBRARIES             list of library dependencies (librarus without cmake config) - relevant only for STATIC
#   SHARED_DEPENDENCY_LIBRARIES             list of library dependencies (librarus without cmake config) - relevant only for SHARED
#   DEPENDENCY_INCLUDE_DIRS                 list of filters containg includefiles needed by the library
#
#   PRIVATE_INCLUDE_DIRS                    list of private incluyde directories (include files only needed for the compilation of trhe lib itself)
#
#   Optional language support
#       CUDA                    if set CUDA support will be enabled
#       CUDA_SOURCE_FILES       list of cuda source files
#       CUDA_HEADER_FILES       list of cuda inlcude files
#
#   Optional input:
#       INSTALL                 if set the library will also be installed
#       BIN_INSTALL_DIR         where to install binary executables <final destination will be <BIN_INSTALL_DIR>
#       LIB_INSTALL_DIR         where to install library files <final destination will be <LIB_INSTALL_DIR>/<NAME>
#       INCLUDE_INSTALL_DIR     where to install include files <final destination will be <INCLUDE_INSTALL_DIR>/<NAME>
#       CMAKE_INSTALL_DIR       where to install cmake config files <final destination will be <CMAKE_INSTALL_DIR>/<NAME>
#
#       Note for all path input: if the distination is empty then the default GNU standard location with be used
#                            if the specified path is relative to final output will go to <CMAKE_INSTALL_PREFIX>/<PATH>
#
#   Create global variables:
#       <NAME>_BINARY_DIR       - folder containg library internal binary files
#       <NAME>_INCLUDE_DIR      - folder containg library internal include files
#       <NAME>_CONFIG_DIR       - folder containg library internal configuration include file

macro(make_library)
    set(options "INSTALL" "CUDA")
    set(oneValueArgs NAME TYPE)
    set(multiValueArgs CXX_SOURCE_FILES 
                       CXX_HEADER_FILES 
                       PRECOMPILED_HEADER_FILES
                       DEPENDENCY_PACKAGES 
                       DEPENDENCY_LIBRARIES 
					   STATIC_DEPENDENCY_LIBRARIES 
					   SHARED_DEPENDENCY_LIBRARIES 
                       DEPENDENCY_INCLUDE_DIRS
                       PRIVATE_INCLUDE_DIRS
                       CUDA_SOURCE_FILES
                       CUDA_HEADER_FILES
                       BIN_INSTALL_DIR
                       LIB_INSTALL_DIR
                       INCLUDE_INSTALL_DIR
                       CMAKE_INSTALL_DIR )
    cmake_parse_arguments(ML "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )    

    # tell what is being done
    fwmessage(STATUS "------------------------------------------------------")
    fwmessage(STATUS "make_library")    
    fwmessage(STATUS "------------------------------------------------------")
    fwmessage(STATUS "  INSTALL                     = ${ML_INSTALL}")
    fwmessage(STATUS "  CUDA                        = ${ML_CUDA}")
    fwmessage(STATUS "  NAME                        = ${ML_NAME}")
    fwmessage(STATUS "  TYPE                        = ${ML_TYPE}")
    fwmessage(STATUS "  CXX_SOURCE_FILES            = ${ML_CXX_SOURCE_FILES}")
    fwmessage(STATUS "  CXX_HEADER_FILES            = ${ML_CXX_HEADER_FILES}")
    fwmessage(STATUS "  PRECOMPILED_HEADER_FILES    = ${ML_PRECOMPILED_HEADER_FILES}")
    fwmessage(STATUS "  DEPENDENCY_PACKAGES         = ${ML_DEPENDENCY_PACKAGES}")
    fwmessage(STATUS "  DEPENDENCY_LIBRARIES        = ${ML_DEPENDENCY_LIBRARIES}")
	fwmessage(STATUS "  STATIC_DEPENDENCY_LIBRARIES = ${ML_STATIC_DEPENDENCY_LIBRARIES}")
	fwmessage(STATUS "  SHARED_DEPENDENCY_LIBRARIES = ${ML_SHARED_DEPENDENCY_LIBRARIES}")
    fwmessage(STATUS "  DEPENDENCY_INCLUDE_DIRS     = ${ML_DEPENDENCY_INCLUDE_DIRS}")
    fwmessage(STATUS "  PRIVATE_INCLUDE_DIRS        = ${ML_PRIVATE_INCLUDE_DIRS}")
    fwmessage(STATUS "  CUDA_SOURCE_FILES           = ${ML_CUDA_SOURCE_FILES}")
    fwmessage(STATUS "  CUDA_HEADER_FILES           = ${ML_CUDA_HEADER_FILES}")
    fwmessage(STATUS "  BIN_INSTALL_DIR             = ${ML_BIN_INSTALL_DIR}")
    fwmessage(STATUS "  INCLUDE_INSTALL_DIR         = ${ML_INCLUDE_INSTALL_DIR}")
    fwmessage(STATUS "  CMAKE_INSTALL_DIR           = ${ML_CMAKE_INSTALL_DIR}")
    
	# select output library type
	set(LIBRARY_TYPE "STATIC_AND_SHARED" CACHE STRING "Output library type (static, shared or both)")
	set_property(CACHE LIBRARY_TYPE PROPERTY STRINGS STATIC SHARED STATIC_AND_SHARED)
	
	# copy some parameters
	set(CORE_NAME ${ML_NAME})
	set(${CORE_NAME}_CONFIG_DIR ${CMAKE_BINARY_DIR})
	set(${CORE_NAME}_BINARY_DIR ${CMAKE_BINARY_DIR})
	    
    # initiate the list of include dirs
    set(PACKAGE_INCLUDE_DIRS)
    
    # handle library naming
    if("${ML_TYPE}" STREQUAL "STATIC" OR "${ML_TYPE}" STREQUAL "STATIC_AND_SHARED" OR  "${ML_TYPE}" STREQUAL "SHARED_AND_STATIC")
        set(BUILD_STATIC ON)
        set(STATIC_LIB_MAME ${CORE_NAME}_static)
        fwmessage(STATUS "STATIC_LIB_MAME = ${STATIC_LIB_MAME}")
        
        realize_package_dependencies(PREFER_STATIC ON OUTPUT_ID PACKAGE_STATIC PACKAGES ${ML_DEPENDENCY_PACKAGES})
        
        list(APPEND PACKAGE_INCLUDE_DIRS ${PACKAGE_STATIC_INCLUDE_DIRS})        
    endif()
    
    if("${ML_TYPE}" STREQUAL "SHARED" OR "${ML_TYPE}" STREQUAL "STATIC_AND_SHARED" OR  "${ML_TYPE}" STREQUAL "SHARED_AND_STATIC")
        set(BUILD_SHARED ON)
        set(SHARED_LIB_MAME ${CORE_NAME})
        fwmessage(STATUS "SHARED_LIB_MAME = ${SHARED_LIB_MAME}")
        
        realize_package_dependencies(PREFER_STATIC OFF OUTPUT_ID PACKAGE_SHARED PACKAGES ${ML_DEPENDENCY_PACKAGES})
        
        list(APPEND PACKAGE_INCLUDE_DIRS ${PACKAGE_SHARED_INCLUDE_DIRS})        
    endif()
    
    # some clean-up
    list(REMOVE_DUPLICATES PACKAGE_INCLUDE_DIRS)
    #list(REMOVE_DUPLICATES PACKAGE_STATIC_LIBRARIES)
    #list(REMOVE_DUPLICATES PACKAGE_SHARED_LIBRARIES)

    # define project files
    set(PROJECT_SOURCE_FILES)   # initiate PROJECT_SOURCE_FILES to empty
    set(PROJECT_HEADER_FILES)   # initiate PROJECT_SOURCE_FILES to empty
    
    # add CXX files
    list(APPEND PROJECT_SOURCE_FILES ${ML_CXX_SOURCE_FILES})
    list(APPEND PROJECT_HEADER_FILES ${ML_CXX_HEADER_FILES})

    #add cuda runtime if requested
    if(ML_CUDA)
        # configure CUDA
        include(cuda)
            
        list(APPEND PROJECT_SOURCE_FILES ${ML_CUDA_SOURCE_FILES})
        list(APPEND PROJECT_HEADER_FILES ${ML_CUDA_HEADER_FILES})    
    endif()

    # handle project config file
    find_file(H_CONFIG_IN config.h.in PATHS ${CMAKE_CURRENT_SOURCE_PATH} ${CMAKE_MODULE_PATH})
    fwmessage(STATUS "H_CONFIG_IN = ${H_CONFIG_IN}")
    configure_file(${H_CONFIG_IN} ${PROJECT_BINARY_DIR}/${CORE_NAME}_config.h)

    # print source files
    fwmessage(STATUS "PROJECT_SOURCE_FILES = ${PROJECT_SOURCE_FILES}")


    # ----------------------------
    # define object library name
    
    # save OBJECT library name
    set(OBJECT_LIB_NAME ${CORE_NAME}_objlib)

    # create common compiled components
    add_library(${OBJECT_LIB_NAME} OBJECT ${PROJECT_SOURCE_FILES} ${PROJECT_HEADER_FILES})

    # set configuration
    set_target_cxx_config(TARGET ${OBJECT_LIB_NAME})
    
    # activate position independant code
    set_target_properties(${OBJECT_LIB_NAME} PROPERTIES POSITION_INDEPENDENT_CODE ON)

    if(ML_CUDA)
        set_target_cuda_config(TARGET ${OBJECT_LIB_NAME})
    endif()

    # set include and library dirs
    target_include_directories(${OBJECT_LIB_NAME} PUBLIC   ${PACKAGE_INCLUDE_DIRS})         # include dirs needed for pagkages
    target_include_directories(${OBJECT_LIB_NAME} PUBLIC   ${ML_DEPENDENCY_INCLUDE_DIRS})    # include dirs needed by specific non packet libraries
    target_include_directories(${OBJECT_LIB_NAME} PRIVATE  ${PROJECT_SOURCE_DIR})           # add project source as private
    target_include_directories(${OBJECT_LIB_NAME} PRIVATE  ${PROJECT_BINARY_DIR})           # add project binary as private
    target_include_directories(${OBJECT_LIB_NAME} PRIVATE  ${ML_PRIVATE_INCLUDE_DIRS})       # add additional private include dirs (like ./include if the project include files are not found in the root)
    
    # precompiled headers
    if(USE_PRECOMPILED_HEADERS) 
        if("${ML_PRECOMPILED_HEADER_FILES}" STREQUAL "")
            target_precompile_headers(${OBJECT_LIB_NAME} PRIVATE ${PROJECT_HEADER_FILES})
        else()
            target_precompile_headers(${OBJECT_LIB_NAME} PRIVATE ${ML_PRECOMPILED_HEADER_FILES}) 
        endif()
    endif()

    # generat find libraries
    if(BUILD_SHARED)
    
        # create the library target
        add_library(${SHARED_LIB_MAME} SHARED $<TARGET_OBJECTS:${OBJECT_LIB_NAME}>)
                        
        # set configuration
        set_target_cxx_config(TARGET ${SHARED_LIB_MAME})
    
        # activate position independant code
        set_target_properties(${OBJECT_LIB_NAME} PROPERTIES POSITION_INDEPENDENT_CODE ON)
            
        # configure include folders
        target_include_directories(${SHARED_LIB_MAME} INTERFACE ${PACKAGE_SHARED_INCLUDE_DIRS} ${ML_DEPENDENCY_INCLUDE_DIRS})
        
        # library linkage
        target_link_libraries(${SHARED_LIB_MAME} PUBLIC ${PACKAGE_SHARED_LIBRARIES} ${ML_DEPENDENCY_LIBRARIES} ${ML_SHARED_DEPENDENCY_LIBRARIES})
                                
        #handle installation
        if(ML_INSTALL)
            install_library(CORE_NAME ${CORE_NAME} 
                            NAME ${SHARED_LIB_MAME} 
                            HEADER_FILES        ${PROJECT_HEADER_FILES}
                            BIN_INSTALL_DIR     ${ML_BIN_INSTALL_DIR}
                            LIB_INSTALL_DIR     ${ML_LIB_INSTALL_DIR}
                            INCLUDE_INSTALL_DIR ${ML_INCLUDE_INSTALL_DIR}
                            CMAKE_INSTALL_DIR   ${ML_CMAKE_INSTALL_DIR}
                            INSTALL_PDB
                            )
        
        endif()         
    endif()
    
    if(BUILD_STATIC)
    
        # create the library target
        add_library(${STATIC_LIB_MAME} STATIC $<TARGET_OBJECTS:${OBJECT_LIB_NAME}>)
                
        # set configuration
        set_target_cxx_config(TARGET ${STATIC_LIB_MAME})
    
        # activate position independant code
        set_target_properties(${OBJECT_LIB_NAME} PROPERTIES POSITION_INDEPENDENT_CODE ON)
        
        # configure include folders
        target_include_directories(${STATIC_LIB_MAME} INTERFACE ${PACKAGE_SHARED_INCLUDE_DIRS} ${ML_DEPENDENCY_INCLUDE_DIRS})
        
        # library linkage
        target_link_libraries(${STATIC_LIB_MAME} PUBLIC ${PACKAGE_STATIC_LIBRARIES} ${ML_DEPENDENCY_LIBRARIES} ${ML_STATIC_DEPENDENCY_LIBRARIES})
                
                    
        #handle installation
        if(ML_INSTALL)
            install_library(CORE_NAME ${CORE_NAME} 
                            NAME ${STATIC_LIB_MAME} 
                            HEADER_FILES        ${PROJECT_HEADER_FILES}
                            BIN_INSTALL_DIR     ${ML_BIN_INSTALL_DIR}
                            LIB_INSTALL_DIR     ${ML_LIB_INSTALL_DIR}
                            INCLUDE_INSTALL_DIR ${ML_INCLUDE_INSTALL_DIR}
                            CMAKE_INSTALL_DIR   ${ML_CMAKE_INSTALL_DIR}  
                            )
        
        endif()         
        
    endif()

	fwmessage(STATUS "------------------------------------------------------")
    fwmessage(STATUS "finished make_library (${CORE_NAME})")
    fwmessage(STATUS "------------------------------------------------------")
      
endmacro()