#define library name
set(LIB_NAME ${CMAKE_PROJECT_NAME}_static)
message(STATUS "-------------------------------------------")
message(STATUS "Generating ${LIB_NAME} static library")
message(STATUS "-------------------------------------------")

# generate the library core name as upper case string
string(TOUPPER ${CMAKE_PROJECT_NAME} LIB_CORENAME_UPPER)
string(TOUPPER ${LIB_NAME} LIB_NAME_UPPER)

# find dependency packages
SET(DEPENDENCY_INCLUDE_DIRS ${INCLUDE_DEPENDENCY_DIRS})
SET(DEPENDENCY_LIBRARIES)
foreach(pck IN LISTS STATIC_DEPENDENCY_LIBS)
	message(STATUS "Locating dependency package: ${pck}")
	find_package(${pck} REQUIRED)
	SET(DEPENDENCY_INCLUDE_DIRS ${DEPENDENCY_INCLUDE_DIRS} ${${pck}_INCLUDE_DIRS})
	SET(DEPENDENCY_LIBRARIES    ${DEPENDENCY_LIBRARIES} ${${pck}_LIBRARIES})
endforeach()

message(STATUS ${DEPEND_INCLUDE_DIRS})
message(STATUS ${DEPEND_LIBRARIES})

# create the library
add_library(${LIB_NAME} STATIC ${SOURCE_FILES} ${HEADER_FILES} ${CUDA_SOURCE_FILES} ${CUDA_HEADER_FILES})
	
#dependencies	
target_include_directories(${LIB_NAME} PUBLIC  ${DEPENDENCY_INCLUDE_DIRS})
target_include_directories(${LIB_NAME} PRIVATE  ${PROJECT_SOURCE_DIR})
target_include_directories(${LIB_NAME} PRIVATE  ${PROJECT_BINARY_DIR})
	
message(STATUS "Depending on: ${DEPEND_LIBRARIES}")
target_link_libraries(${LIB_NAME} PUBLIC ${DEPENDENCY_LIBRARIES})
	
# precompiled headers
if(USE_PRECOMPILED_HEADERS)
	target_precompile_headers(${LIB_NAME} PRIVATE ${HEADER_FILES})
endif()
	
# compile options
target_compile_features(${LIB_NAME} PUBLIC cxx_std_17)
set_target_properties(${LIB_NAME} PROPERTIES POSITION_INDEPENDENT_CODE ON)
	
# set target properties
set_target_properties(${LIB_NAME} PROPERTIES VERSION "${CMAKE_PROJECT_VERSION_MAJOR}.${CMAKE_PROJECT_VERSION_MINOR}.${CMAKE_PROJECT_VERSION_PATCH}")

# append d to debug libraries
set_property(TARGET ${LIB_NAME} PROPERTY DEBUG_POSTFIX d)

# If using MSVC the set the debug database filename
IF(MSVC)
	set_property(TARGET ${LIB_NAME} PROPERTY COMPILE_PDB_NAME_DEBUG "${LIB_NAME}d")
	set_property(TARGET ${LIB_NAME} PROPERTY COMPILE_PDB_NAME_RELWITHDEBINFO "${LIB_NAME}")
ENDIF()


#installation
include(cmake/lib_install.cmake)
