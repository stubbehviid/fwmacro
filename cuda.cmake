if(NOT CUDA_CONFIGURED)
	set(CUDA_CONFIGURED TRUE)
	message(STATUS "Configuring for CUDA use")

	# Some CUDA specific option
	OPTION (USE_CUDA_FAST_MATH "Use CUDA fast math intrinsics" OFF)


	# activate seperable compilation (must be set before enable_language)
	set(CUDA_SEPARABLE_COMPILATION ON)
	find_package(CUDA QUIET REQUIRED)
		
	# enable CUDA language
	enable_language(CUDA)
		
	set(CMAKE_CUDA_GENERAL_FLAGS ${CMAKE_CUDA_FLAGS} --device-link)# --std=c++17)
	
	if(USE_CUDA_FAST_MATH)
		set(CMAKE_CUDA_GENERAL_FLAGS ${CMAKE_CUDA_GENERAL_FLAGS} -use_fast_math)
	endif()
	
	# various language options
	#set(CMAKE_CUDA_GENERAL_FLAGS ${CMAKE_CUDA_GENERAL_FLAGS} -Xcudafe 
	#														 --diag_suppress=extra_semicolon 
	#														 --diag_suppress=exception_spec_override_incompat
	#														 --diag_suppress=boolean_controlling_expr_is_constant
	#														 --diag_suppress=unsigned_compare_with_zero
	#														--diag_suppress=generated_exception_spec_override_incompat )
	
	set(CMAKE_CUDA_FLAGS_STATIC ${CMAKE_CUDA_GENERAL_FLAGS} -cudart static)
	set(CMAKE_CUDA_FLAGS_SHARED ${CMAKE_CUDA_GENERAL_FLAGS} -cudart shared)
	
		
	# locate the CUDA toolkit
	
	# Determine architecture under windows
	if(WIN32)
		set(PLATFORM_SUB_LIB_DIR "/${CMAKE_VS_PLATFORM_TOOLSET_HOST_ARCHITECTURE}")
	else()
		set(PLATFORM_SUB_LIB_DIR "")
	endif()

	# determine toolkit dir
	string(FIND ${CMAKE_CUDA_COMPILER} "/bin/nvcc" POS )
	string(SUBSTRING ${CMAKE_CUDA_COMPILER} 0 ${POS} CUDA_TOOLKIT_DIR)

	# define location of libraries and include files
	set(CUDA_INCLUDE_DIRS "${CUDA_TOOLKIT_DIR}/include" CACHE PATH "CUDA Include Directory")
	set(CUDA_LIBRARY_DIR "${CUDA_TOOLKIT_DIR}/lib/${PLATFORM_SUB_LIB_DIR}" CACHE PATH "CUDA Library Directory")

	# Find all the required cuda libraries

	# start with the runtime
	set(CUDA_LIBRARIES_STATIC cudart_static)
	set(CUDA_LIBRARIES_SHARED cudart)

	# search for cuda utility libraries
	# find the test source files
	file(GLOB CUDALIBS RELATIVE ${CUDA_LIBRARY_DIR} ${CUDA_LIBRARY_DIR}/cublas*.* 
													${CUDA_LIBRARY_DIR}/cufft*.* 
													${CUDA_LIBRARY_DIR}/curand* 
													${CUDA_LIBRARY_DIR}/cusolver* 
													${CUDA_LIBRARY_DIR}/cusparce*.* 
													${CUDA_LIBRARY_DIR}/npp*.* 
													${CUDA_LIBRARY_DIR}/nvblas.* 
													${CUDA_LIBRARY_DIR}/nvjpeg*)
	# Strip file extensionm of library names
	foreach(X IN LISTS CUDALIBS)	
		get_filename_component(Y ${X} NAME_WLE)	
		set(CUDA_LIBRARIES_STATIC ${CUDA_LIBRARIES_STATIC} ${Y})
		set(CUDA_LIBRARIES_SHARED ${CUDA_LIBRARIES_SHARED} ${Y})
	endforeach()

	message(STATUS "CMAKE_CUDA_COMPILER   	= ${CMAKE_CUDA_COMPILER}")
	message(STATUS "CMAKE_CUDA_FLAGS      	= ${CMAKE_CUDA_FLAGS}")
	message(STATUS "CUDA_INCLUDE_DIRS     	= ${CUDA_INCLUDE_DIRS}")
	message(STATUS "CUDA_LIBRARY_DIR      	= ${CUDA_LIBRARY_DIR}")
	message(STATUS "CUDA_LIBRARIES_STATIC 	= ${CUDA_LIBRARIES_STATIC}")
	message(STATUS "CUDA_LIBRARIES_SHARED 	= ${CUDA_LIBRARIES_STATIC}")
	message(STATUS "CMAKE_CUDA_FLAGS_STATIC = ${CMAKE_CUDA_FLAGS_STATIC}")
	message(STATUS "CMAKE_CUDA_FLAGS_SHARED = ${CMAKE_CUDA_FLAGS_SHARED}")

endif()
