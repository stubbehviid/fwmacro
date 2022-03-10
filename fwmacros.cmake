
# macro: fwmessage
#   verbosity macro for std cmake message alllowing control of verbosity
macro(fwmessage _type _text)

    if(FWMACROS_VERBOSE)
        message(${_type} "${_text}")
    endif() 
endmacro()

# load standard path names (std cmake module)
include(GNUInstallDirs)

# load std lib options
include(fwlib_options)

# include compiler options
include(fwcompiler)


# macro: realize_package_dependency
#       find and activate specific package dependency
#
# realize_package_dependency(PREFER_STATIC <bool> OUTPUT_ID <name> PACKAGE <package name string>)
#
# REQUIRED          if set the package is required
# PREFER_STATIC     if option set the macro will look for the static version of the package before the shared version (else the other way around)
# OUTPUT_ID     the macro will generate two variables named <OUTPUT_ID>_INCLUDE_DIRS and <OUTPUT_ID>_LIBRARIES  containg the resolved package info
# PACKAGE       the name of the package to be resolved
#                packages with submodules can be accessed using the syntax: <package name>[<sub1>,<sub2>,...,<subN>]
#
# example realize_package_dependencies(OUTPUT_ID LIBS PACKAGES fwstdlib Qt5[core,widgets]
macro(realize_package_dependency)
    set(options )
    set(oneValueArgs "OUTPUT_ID" "PACKAGE" "PREFER_STATIC" "REQUIRED")
    set(multiValueArgs )
    cmake_parse_arguments(RP "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )    

    fwmessage(STATUS "--- realize_package_dependency ---")
    fwmessage(STATUS "Resolving package ${RP_PACKAGE}")
    fwmessage(STATUS "   OUTPUT_ID     = ${RP_OUTPUT_ID}")
    fwmessage(STATUS "   PREFER_STATIC = ${RP_PREFER_STATIC}")
    fwmessage(STATUS "   PACKAGE        = ${RP_PACKAGE}")
    
    # initiate output to fail
    set(${RP_OUTPUT_ID}_LIBRARIES )
    set(${RP_OUTPUT_ID}_INCLUDE_DIRS )
    set(${RP_OUTPUT_ID}_FOUND OFF )
    
    string(FIND ${RP_PACKAGE} "[" pos)
    if(pos EQUAL -1)
        fwmessage(STATUS "    - Simple package")
        set(CORE_PACKAGE ${RP_PACKAGE})
        set(STATIC_NAME ${CORE_PACKAGE}_static)
        set(SHARED_NAME ${CORE_PACKAGE})
        
        if(RP_PREFER_STATIC)
            fwmessage(STATUS "    - looking for static: ${STATIC_NAME}")
            find_package(${STATIC_NAME})
            if(${STATIC_NAME}_FOUND)
                fwmessage(STATUS "    - found static version of ${CORE_PACKAGE}")
                set(${RP_OUTPUT_ID}_LIBRARIES ${${STATIC_NAME}_LIBRARIES})
                set(${RP_OUTPUT_ID}_INCLUDE_DIRS ${${STATIC_NAME}_INCLUDE_DIRS})
                set(${RP_OUTPUT_ID}_FOUND ON)    
            else()
                fwmessage(STATUS "    - static not found then try shared")
                find_package(${SHARED_NAME})
                if(${SHARED_NAME}_FOUND)
                    fwmessage(STATUS "    - found shared version of ${CORE_PACKAGE}")
                    set(${RP_OUTPUT_ID}_LIBRARIES ${${SHARED_NAME}_LIBRARIES})
                    set(${RP_OUTPUT_ID}_INCLUDE_DIRS ${${SHARED_NAME}_INCLUDE_DIRS})
                    set(${RP_OUTPUT_ID}_FOUND ON)                        
                endif()
            endif()
            
        else()
            fwmessage(STATUS "   - looking for shared: ${SHARED_NAME}")
            find_package(${SHARED_NAME})
            if(${SHARED_NAME}_FOUND)
                fwmessage(STATUS "    - found shared version of ${CORE_PACKAGE}")
                set(${RP_OUTPUT_ID}_LIBRARIES ${${SHARED_NAME}_LIBRARIES})
                set(${RP_OUTPUT_ID}_INCLUDE_DIRS ${${SHARED_NAME}_INCLUDE_DIRS})
                set(${RP_OUTPUT_ID}_FOUND ON)        
            else()
                fwmessage(STATUS "    - static not found then try static")
                find_package(${STATIC_NAME})
                if(${STATIC_NAME}_FOUND)
                    fwmessage(STATUS "    - found static version of ${CORE_PACKAGE}")
                    set(${RP_OUTPUT_ID}_LIBRARIES ${${STATIC_NAME}_LIBRARIES})
                    set(${RP_OUTPUT_ID}_INCLUDE_DIRS ${${STATIC_NAME}_INCLUDE_DIRS})
                    set(${RP_OUTPUT_ID}_FOUND ON)                        
                endif()
            endif()
        endif()
    
    else()
        fwmessage(STATUS "    - package with components")
    
        # parse component list
        string(LENGTH "${RP_PACKAGE}" len)
        string(SUBSTRING "${RP_PACKAGE}" 0 ${pos} CORE_PACKAGE)
        string(SUBSTRING "${RP_PACKAGE}" ${pos}+1 ${len}  MODULES)
        string(STRIP "${MODULES}" MODULES)
        string(REGEX REPLACE "[\]\[]" "" MODULES "${MODULES}")
        string(REGEX REPLACE "[,]" ";" MODULES "${MODULES}")
    
        fwmessage(STATUS "    - CORE_PACKAGE = ${CORE_PACKAGE}")
        fwmessage(STATUS "    - MODULES      = ${MODULES}")
        
        if(RP_PREFER_STATIC)
            fwmessage(STATUS "    - looking for static: ${STATIC_NAME}")
            find_package(${STATIC_NAME} COMPONENTS ${MODULES})
            if(${STATIC_NAME}_FOUND)
                fwmessage(STATUS "    - found static version of ${CORE_PACKAGE}")               
                foreach(sub IN LISTS MODULES)       
                    list(APPEND ${RP_OUTPUT_ID}_LIBRARIES    ${${${STATIC_NAME}}${sub}_LIBRARIES})               
                    list(APPEND ${RP_OUTPUT_ID}_INCLUDE_DIRS ${${${STATIC_NAME}}${sub}_INCLUDE_DIRS})                    
                endforeach()
                set(${RP_OUTPUT_ID}_FOUND ON)
            else()
                fwmessage(STATUS "    - static not found then try shared")
                find_package(${SHARED_NAME} COMPONENTS ${MODULES})
                if(${SHARED_NAME}_FOUND)
                    fwmessage(STATUS "    - found shared version of ${CORE_PACKAGE}")
                    foreach(sub IN LISTS MODULES)       
                        list(APPEND ${RP_OUTPUT_ID}_LIBRARIES    ${${${SHARED_NAME}}${sub}_LIBRARIES})               
                        list(APPEND ${RP_OUTPUT_ID}_INCLUDE_DIRS ${${${SHARED_NAME}}${sub}_INCLUDE_DIRS})                    
                    endforeach()
                    set(${RP_OUTPUT_ID}_FOUND ON)                        
                endif()
            endif()
            
        else()
            fwmessage(STATUS "   - looking for shared: ${SHARED_NAME}")
            find_package(${SHARED_NAME} COMPONENTS ${MODULES})
            if(${SHARED_NAME}_FOUND)
                fwmessage(STATUS "    - found shared version of ${CORE_PACKAGE}")
                foreach(sub IN LISTS MODULES)       
                    list(APPEND ${RP_OUTPUT_ID}_LIBRARIES    ${${${SHARED_NAME}}${sub}_LIBRARIES})               
                    list(APPEND ${RP_OUTPUT_ID}_INCLUDE_DIRS ${${${SHARED_NAME}}${sub}_INCLUDE_DIRS})                    
                endforeach()
                set(${RP_OUTPUT_ID}_FOUND ON)        
            else()
                fwmessage(STATUS "    - static not found then try static")
                find_package(${STATIC_NAME} COMPONENTS ${MODULES})
                if(${STATIC_NAME}_FOUND)
                    fwmessage(STATUS "    - found static version of ${CORE_PACKAGE}")
                    foreach(sub IN LISTS MODULES)       
                        list(APPEND ${RP_OUTPUT_ID}_LIBRARIES    ${${${STATIC_NAME}}${sub}_LIBRARIES})               
                        list(APPEND ${RP_OUTPUT_ID}_INCLUDE_DIRS ${${${STATIC_NAME}}${sub}_INCLUDE_DIRS})                    
                    endforeach()
                    set(${RP_OUTPUT_ID}_FOUND ON)                        
                endif()
            endif()
        endif()
    
    endif()
    
    fwmessage(STATUS "    - ${RP_OUTPUT_ID}_LIBRARIES    = ${${RP_OUTPUT_ID}_LIBRARIES}")
    fwmessage(STATUS "    - ${RP_OUTPUT_ID}_INCLUDE_DIRS = ${${RP_OUTPUT_ID}_INCLUDE_DIRS}")
    fwmessage(STATUS "    - ${RP_OUTPUT_ID}_FOUND        = ${${RP_OUTPUT_ID}_FOUND}")
    fwmessage(STATUS "Done resolving package ${RP_PACKAGE}")
    
    # throw hard failure if requested
    if(NOT ${RP_OUTPUT_ID}_FOUND AND RP_REQUIRED)
        message(FATAL_ERROR "Cannot find package ${RP_PACKAGE}")
    endif()     
endmacro()

# macro: realize_package_dependencies
#       find and activate a list of dependency packages (libraries with assicuate cmake config)
#
# realize_package_dependencies(OUTPUT_ID <name> PACKAGES <list of packages>
#
# PREFER_STATIC     if option set realize_package_dependencies will look for static package version first else shared
# OUTPUT_ID  the macro with generate two variables named <OUTPUT_ID>_INCLUDE_DIRS and <OUTPUT_ID>_LIBRARIES
# PACKAGES     list of packages to be included
#              packages with submodules can be accessed using <package name>[<sub1>,<sub2>,...,<subN>]
#
# example realize_package_dependencies(OUTPUT_ID LIBS PACKAGES fwstdlib Qt5[core,widgets]
macro(realize_package_dependencies)
    set(options )
    set(oneValueArgs "OUTPUT_ID" "PREFER_STATIC" "REQUIRED")
    set(multiValueArgs "PACKAGES")
    cmake_parse_arguments(RPD "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )    

    set(DERPD_OUT_ID ${RPD_OUTPUT_ID})

    fwmessage(STATUS "--- realize_package_dependencies ---")

    fwmessage(STATUS "RPD_OUTPUT_ID       = ${DERPD_OUT_ID}")
    fwmessage(STATUS "RPD_PREFER_STATIC   = ${RPD_PREFER_STATIC}")
    fwmessage(STATUS "RPD_REQUIRED        = ${RPD_REQUIRED}")

    set(${RPD_OUTPUT_ID}_INCLUDE_DIRS)
    set(${RPD_OUTPUT_ID}_LIBRARIES)


    foreach(pck IN LISTS RPD_PACKAGES)
        fwmessage(STATUS "Resolving package dependency: ${pck}")
    
        realize_package_dependency(OUTPUT_ID PC PREFER_STATIC ${RPD_PREFER_STATIC} REQUIRED ${RPD_REQUIRED} PACKAGE ${pck})
    
        if(PC_FOUND)            
            list(APPEND ${DERPD_OUT_ID}_LIBRARIES ${PC_LIBRARIES})
            list(APPEND ${DERPD_OUT_ID}_INCLUDE_DIRS ${PC_INCLUDE_DIRS})
        endif()         
    endforeach()
    
    list(REMOVE_DUPLICATES ${DERPD_OUT_ID}_INCLUDE_DIRS)
    list(REMOVE_DUPLICATES ${DERPD_OUT_ID}_LIBRARIES) 
    
    fwmessage(STATUS "${DERPD_OUT_ID}_INCLUDE_DIRS = ${${DERPD_OUT_ID}_INCLUDE_DIRS}")
    fwmessage(STATUS "${DERPD_OUT_ID}_LIBRARIES = ${${DERPD_OUT_ID}_LIBRARIES}")
    
    fwmessage(STATUS "--- Done realize_package_dependencies")
endmacro()

# macro: realize_install_path
#       utility macro for converting a path to a fully qualified path relative to the install prefix
#
# define macro for cleanly expanding a path to its fully qualified version handling default values
macro(realize_install_path _name _def)
  if(NOT IS_ABSOLUTE ${${_name}})  
    if("${${_name}}" STREQUAL "")
      set(${_name} ${_def})
    endif()
    if("${${_name}}" STREQUAL "<default>")
      set(${_name} ${_def})
    endif()
    if(NOT IS_ABSOLUTE ${${_name}})
      set(${_name} "${CMAKE_INSTALL_PREFIX}/${${_name}}")
    endif()     
  endif()
endmacro()

# macro: install_retain_dir_exclude_include
#       utility macro for handlig installation of include files
#
# macro for installing files maintaining relative directory stricture Trim the first folder of the destination path 
# so if include/dir1/dir2/file.h is input the destination will be dir1/dir2)
macro(install_retain_dir_exclude_include)
    set(options "")
    set(oneValueArgs "DESTINATION")
    set(multiValueArgs "FILES")
    cmake_parse_arguments(CAS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )  

    foreach(FILE ${CAS_FILES})          
        # set default sub path
        set(SFILE ${FILE})
    
        # split path into list
        string(REGEX REPLACE "[/\]" ";" PATH_LIST ${FILE})  # turn path into a list
        
        # check if first element in path list is "include" if so remove the node
        list(GET PATH_LIST 0 FIRST_FOLDER)
        
        if("${FIRST_FOLDER}" STREQUAL "include")
            list(POP_FRONT PATH_LIST PATH_LIST)                 # remove first entry in list if number of elements in path > 1 (we do not want to delete the filename itself)
            list(JOIN PATH_LIST "/" SFILE)                      # list back to path
        endif()
            
        get_filename_component(DIR ${SFILE} DIRECTORY)      # extract the relative sub folder to use as destination
        fwmessage(STATUS "FILE:${FILE}   ->   DIR=${CAS_DESTINATION}/${DIR}")
        install(FILES ${FILE} DESTINATION ${CAS_DESTINATION}/${DIR})    # install the file
    endforeach()
endmacro()

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





# macro: make_library
#       create a library project including cmake config files
#
#   NAME <library name>                     Name of the library to be generated
#   TYPE <type>                             Either STATIC, SHARED or STATIC_AND_SHARED
#   CXX_SOURCE_FILES                        list of c++ source files
#   CXX_HEADER_FILES                        list of c++ header files
#   PRECOMPILED_HEADER_FILES                list of include files to be used for precompiled headers (If not set CXX_HEADER_FILES will be used if precompiled headers are active)
#   DEPENDENCY_PACKAGES                     list of dependency packages (libraries with cmake config)
#   DEPENDENCY_LIBRARIES                            list of library dependencies (librarus without cmake config)
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
    fwmessage(STATUS "  INSTALL                   = ${ML_INSTALL}")
    fwmessage(STATUS "  CUDA                      = ${ML_CUDA}")
    fwmessage(STATUS "  NAME                      = ${ML_NAME}")
    fwmessage(STATUS "  TYPE                      = ${ML_TYPE}")
    fwmessage(STATUS "  CXX_SOURCE_FILES          = ${ML_CXX_SOURCE_FILES}")
    fwmessage(STATUS "  CXX_HEADER_FILES          = ${ML_CXX_HEADER_FILES}")
    fwmessage(STATUS "  PRECOMPILED_HEADER_FILES  = ${ML_PRECOMPILED_HEADER_FILES}")
    fwmessage(STATUS "  DEPENDENCY_PACKAGES       = ${ML_DEPENDENCY_PACKAGES}")
    fwmessage(STATUS "  DEPENDENCY_LIBRARIES      = ${ML_DEPENDENCY_LIBRARIES}")
    fwmessage(STATUS "  DEPENDENCY_INCLUDE_DIRS   = ${ML_DEPENDENCY_INCLUDE_DIRS}")
    fwmessage(STATUS "  PRIVATE_INCLUDE_DIRS      = ${ML_PRIVATE_INCLUDE_DIRS}")
    fwmessage(STATUS "  CUDA_SOURCE_FILES         = ${ML_CUDA_SOURCE_FILES}")
    fwmessage(STATUS "  CUDA_HEADER_FILES         = ${ML_CUDA_HEADER_FILES}")
    fwmessage(STATUS "  BIN_INSTALL_DIR           = ${ML_BIN_INSTALL_DIR}")
    fwmessage(STATUS "  INCLUDE_INSTALL_DIR       = ${ML_INCLUDE_INSTALL_DIR}")
    fwmessage(STATUS "  CMAKE_INSTALL_DIR         = ${ML_CMAKE_INSTALL_DIR}")
    
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
    list(REMOVE_DUPLICATES PACKAGE_STATIC_LIBRARIES)
    list(REMOVE_DUPLICATES PACKAGE_SHARED_LIBRARIES)

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
        target_link_libraries(${SHARED_LIB_MAME} PUBLIC ${PACKAGE_SHARED_LIBRARIES} ${ML_DEPENDENCY_LIBRARIES})
                                
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
        target_link_libraries(${STATIC_LIB_MAME} PUBLIC ${PACKAGE_STATIC_LIBRARIES} ${ML_DEPENDENCY_LIBRARIES})
                
                    
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
    fwmessage(STATUS "make_executable (${EXE_NAME})")   
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
    realize_package_dependencies(PREFER_STATIC ${${ME_NAME}_LINK_AGAINST_STATIC} OUTPUT_ID PACKAGES ${ME_DEPENDENCY_PACKAGES})
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
            
    target_link_libraries(${EXE_NAME} ${PACKAGE_LIBRARIES} ${ME_DEPENDENCY_LIBRARIES})  # link resolved packages and specific input list of libraries
    
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

# macro: make_library_tests
#       create a standard unit test project
#
#   LIB_NAME <name>                         name of library for which the unit tests are made
#   TEST_MASK <mask>                        file search mask for finding test source files (typically "*_test.cpp")
#   DEPENDENCY_PACKAGES                     list of dependency packages (libraries with cmake config)
#   DEPENDENCY_LIBRARIES                            list of library dependencies (libraries without cmake config)
#   DEPENDENCY_INCLUDE_DIRS                 list of filters containg includefiles needed by the library
#
#   PRIVATE_INCLUDE_DIRS                    list of private include directories (include files only needed for the compilation of the executable
#   Optional language support
#       CUDA                    if set CUDA support will be enabled

#
macro(make_library_tests)

set(options "CUDA")
    set(oneValueArgs LIB_NAME TEST_MASK)
    set(multiValueArgs DEPENDENCY_PACKAGES 
                       DEPENDENCY_LIBRARIES 
                       DEPENDENCY_INCLUDE_DIRS
                       PRIVATE_INCLUDE_DIRS
                       CUDA_SOURCE_FILES
                       CUDA_HEADER_FILES )
    cmake_parse_arguments(MT "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )    

    # tell what is being generated
    fwmessage(STATUS "------------------------------------------------------")
    fwmessage(STATUS "make_library_tests (${MT_LIB_NAME})")  
    fwmessage(STATUS "------------------------------------------------------")
	fwmessage(STATUS "  CUDA                      = ${MT_CUDA}")
	fwmessage(STATUS "  LIB_NAME                  = ${MT_LIB_NAME}")
	fwmessage(STATUS "  TEST_MASK                 = ${MT_TEST_MASK}")
	fwmessage(STATUS "  DEPENDENCY_PACKAGES       = ${MT_DEPENDENCY_PACKAGES}")
	fwmessage(STATUS "  DEPENDENCY_LIBRARIES      = ${MT_DEPENDENCY_LIBRARIES}")
	fwmessage(STATUS "  DEPENDENCY_INCLUDE_DIRS   = ${MT_DEPENDENCY_INCLUDE_DIRS}")
	fwmessage(STATUS "  PRIVATE_INCLUDE_DIRS      = ${MT_PRIVATE_INCLUDE_DIRS}")
	fwmessage(STATUS "  CUDA_SOURCE_FILES         = ${MT_CUDA_SOURCE_FILES}")
	fwmessage(STATUS "  CUDA_HEADER_FILES         = ${MT_CUDA_HEADER_FILES}")

    # enable testing 
    enable_testing ()

    OPTION (USE_EXTERNAL_CATCH2_INSTALL "If set use an external version of the catch2 test environment" ON)
    OPTION (LINK_TESTS_AGAINST_STATIC "Link unit tests against static version of library" ON)
    
    # determine which library to link against
    if(LINK_TESTS_AGAINST_STATIC)
        set(LIB_NAME ${MT_LIB_NAME}_static)
    else()
        set(LIB_NAME ${MT_LIB_NAME})
    endif()
    message(STATUS "linking tests against: ${LIB_NAME}")

    # handle defaults for TEST_MASK
    if("${MT_TEST_MASK}" STREQUAL "")
        set(MT_TEST_MASK "*_test.cpp")
    endif()
    fwmessage(STATUS "Searching for tests using file mask    = ${MT_TEST_MASK}")

    # handle linkage of catch2 test environment
    if(USE_EXTERNAL_CATCH2_INSTALL)
        find_package(Catch2 2 REQUIRED)
    else()
        # get the catch2 test environment
        Include(FetchContent)   

        # download catch2 from github
        FetchContent_Declare(Catch2
                            GIT_REPOSITORY https://github.com/catchorg/Catch2.git
                            GIT_TAG        v2.13.8
                            )
        # make it available
        FetchContent_MakeAvailable(Catch2)
    endif()

    # find the test source files
    file(GLOB TEST_SOURCE_FILES RELATIVE  ${CMAKE_CURRENT_SOURCE_DIR} "${CMAKE_CURRENT_SOURCE_DIR}/${MT_TEST_MASK}")
    fwmessage(STATUS "Found test source files    = ${TEST_SOURCE_FILES}")

    if(MT_CUDA)
        make_executable(NAME tests 
                        CXX_SOURCE_FILES ${TEST_SOURCE_FILES}
						PRECOMPILED_HEADER_FILES "${CMAKE_CURRENT_SOURCE_DIR}/../include/${MT_LIB_NAME}.h"
                        DEPENDENCY_PACKAGES ${MT_DEPENDENCY_PACKAGES}
                        DEPENDENCY_LIBRARIES ${MT_DEPENDENCY_LIBRARIES}
                        DEPENDENCY_INCLUDE_DIRS ${MT_DEPENDENCY_INCLUDE_DIRS}
                        PRIVATE_INCLUDE_DIRS ${MT_PRIVATE_INCLUDE_DIRS}
                        CUDA
                        CUDA_SOURCE_FILES ${MT_CUDA_SOURCE_FILES}
                        CUDA_HEADER_FILES ${MT_CUDA_HEADER_FILES}
                        )
    
    else()
        make_executable(NAME tests 
                        CXX_SOURCE_FILES ${TEST_SOURCE_FILES}
						PRECOMPILED_HEADER_FILES "${CMAKE_CURRENT_SOURCE_DIR}/../include/${MT_LIB_NAME}.h"
                        DEPENDENCY_PACKAGES ${MT_DEPENDENCY_PACKAGES}
                        DEPENDENCY_LIBRARIES ${MT_DEPENDENCY_LIBRARIES}
                        DEPENDENCY_INCLUDE_DIRS ${MT_DEPENDENCY_INCLUDE_DIRS}
                        PRIVATE_INCLUDE_DIRS ${MT_PRIVATE_INCLUDE_DIRS}
                        )
    endif()
	
	# add reference to the target library itself
	target_include_directories(tests PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/../include"
											 "${${MT_LIB_NAME}_CONFIG_DIR}" 
											 "${PROJECT_BINARY_DIR}"
											)	# link to include files inside the source tree
	target_link_libraries(tests Catch2::Catch2 ${LIB_NAME})    
        
    # add links to target library
    target_include_directories(tests PRIVATE ${${MT_LIB_NAME}_INCLUDE_DIR} ${${MT_LIB_NAME}_CONFIG_DIR} ${PROJECT_BINARY_DIR})
    target_link_directories(tests PRIVATE ${${MT_LIB_NAME}_BINARY_DIR})
    target_link_libraries(tests Catch2::Catch2 ${LIB_NAME})
    
    # work around for internal catch2 installation
    if(NOT USE_EXTERNAL_CATCH2_INSTALL)
        list(APPEND CMAKE_MODULE_PATH ${catch2_SOURCE_DIR}/extras)
    endif()
    
    include(CTest)
    include(Catch)
    catch_discover_tests(tests)
endmacro()