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
        
    # add links to target library
    target_include_directories(tests PRIVATE ${${MT_LIB_NAME}_INCLUDE_DIR} ${${MT_LIB_NAME}_CONFIG_DIR} ${PROJECT_BINARY_DIR})
    target_link_directories(tests PRIVATE ${${MT_LIB_NAME}_BINARY_DIR})
    target_link_libraries(tests PRIVATE Catch2::Catch2 ${LIB_NAME})
    
    # work around for internal catch2 installation
    if(NOT USE_EXTERNAL_CATCH2_INSTALL)
        list(APPEND CMAKE_MODULE_PATH ${catch2_SOURCE_DIR}/extras)
    endif()
    
    include(CTest)
    include(Catch)
    catch_discover_tests(tests)
endmacro()