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
    #list(REMOVE_DUPLICATES ${DERPD_OUT_ID}_LIBRARIES) 
    
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