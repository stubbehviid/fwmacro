# activate seperable compilation (must be set before enable_language)
set(CUDA_SEPARABLE_COMPILATION ON)
find_package(CUDA QUIET REQUIRED)
	
# enable CUDA language
enable_language(CUDA)
	
set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} --device-link")
if(NOT WIN32)
  set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} --std=c++17")
endif()
if(USE_CUDA_FAST_MATH)
	set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -use_fast_math")
endif()
	
if(CUDA_USE_STATIC_CUDA_RUNTIME)
	set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -cudart static")
else()
	set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -cudart shared")
endif()
	
set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -Xcudafe --diag_suppress=extra_semicolon")
set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -Xcudafe --diag_suppress=exception_spec_override_incompat")
set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -Xcudafe --diag_suppress=boolean_controlling_expr_is_constant")
set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -Xcudafe --diag_suppress=unsigned_compare_with_zero")
set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -Xcudafe --diag_suppress=generated_exception_spec_override_incompat")

# determine toolkit dir
string(FIND ${CMAKE_CUDA_COMPILER} "/bin/nvcc" POS )
string(SUBSTRING ${CMAKE_CUDA_COMPILER} 0 ${POS} CUDA_TOOLKIT_DIR)

set(CUDA_INCLUDE_DIRS "${CUDA_TOOLKIT_DIR}/include" CACHE PATH "CUDA Include Directory")
set(CUDA_LIBRARY_DIR "${CUDA_TOOLKIT_DIR}/lib/x64" CACHE PATH "CUDA Library Directory")