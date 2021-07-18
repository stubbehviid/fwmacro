#--------
# options
#--------
# compiter optimizations
set(COMPILER_OPT_MODE "COMP_OPT_NORMAL" CACHE STRING "Compiler optimization level")
set_property(CACHE COMPILER_OPT_MODE PROPERTY STRINGS COMP_OPT_NONE COMP_OPT_NORMAL COMP_OPT_FULL)

# SIMD mode
set(SIMD_MODE "SIMD_AVX2" CACHE STRING "Optimize using specified SIMD mode")
set_property(CACHE SIMD_MODE PROPERTY STRINGS SIMD_NONE SIMD_SSE SIMD_SSE2 SIMD_AVX SIMD_AVX2 SIMD_AVX512)

# C++ standard
set(COMPILER_STANDARD "cxx_std_17" CACHE STRING "C++ language standard")
set_property(CACHE COMPILER_STANDARD PROPERTY STRINGS cxx_std_98 cxx_std_11 cxx_std_14 cxx_std_17 cxx_std_20 cxx_std_23)

if(MSVC)
	OPTION (USE_MSCV_EXPERIMENTAL_OPENMP "use the MSVC --openmp:experimental clause" ON)
else()

endif()

# -------------------
# Configure SIMD mode
# -------------------
if( SIMD_MODE STREQUAL "SIMD_SSE" )
 set(USE_SSE TRUE)
elseif( SIMD_MODE STREQUAL "SIMD_SSE2" )
 set(USE_SSE2 TRUE)
elseif( SIMD_MODE STREQUAL "SIMD_AVX" )
 set(USE_AVX TRUE)
elseif( SIMD_MODE STREQUAL "SIMD_AVX2" )
 set(USE_AVX2 TRUE)
elseif( SIMD_MODE STREQUAL "SIMD_AVX512" )
 set(USE_AVX512 TRUE)
endif()

# ---------------------------
# compiler optimization flags
# ---------------------------
if( COMPILER_OPT_MODE STREQUAL "COMP_OPT_NORMAL" )	
	if(MSVC)	# MSVC style compilers		
		message(STATUS "Using MSVC - Normal Compiler Optimizations")
		set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /O2 /Oi /Ob2")
		set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} /O2 /Oi /Ob2")
	else()		# clang and g++ style compilers	
		message(STATUS "Using Normal Compiler Optimizations")
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3") 
	endif()
elseif( COMPILER_OPT_MODE STREQUAL "COMP_OPT_FULL" )	
	if(MSVC)
		message(STATUS "Using MSVC - Full Compiler Optimizations")
		set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /O2 /Oi /Ob2 /Ot /GT /GL")
		set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} /O2 /Oi /Ob2 /Ot")	
		set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /LTCG")
	else()		# clang and g++ style compilers	
		message(STATUS "Using Full Compiler Optimizations")
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -ffast-math") 
	endif()
else()
	# COMP_OPT_NONE settings
endif()


# SIMD settings
if(USE_SSE)
	message(STATUS "Building with SSE SIMD code generation")
	if(MSVC)
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /arch:SSE")
	else()
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -msse")
	endif()
elseif(USE_SSE2)
	message(STATUS "Building with SSE2 SIMD code generation")
	if(MSVC)
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /arch:SSE2")
	else()
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -msse2")
	endif()
elseif(USE_AVX)
	message(STATUS "Building with AVX SIMD code generation")
	if(MSVC)
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /arch:AVX")
	else()
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mavx")
	endif()
elseif(USE_AVX2)
	message(STATUS "Building with AVX2 SIMD code generation")
	if(MSVC)
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /arch:AVX2")
	else()
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mavx2 -mfma")
	endif()
elseif(USE_AVX512)
	message(STATUS "Building with AVX512 SIMD code generation")
	if(MSVC)
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /arch:AVX512")
	else()
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mavx512")
	endif()
endif()

#-----------------------------------------
# set additional compiler specific options
#-----------------------------------------

IF(MSVC)
	# MSVC WIN32 specific settings
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /wd4244 /wd4267 /wd4018 /nologo /W1 /EHsc /MP")
	add_definitions( "-DWIN32_LEAN_AND_MEAN -D_CRT_SECURE_NO_WARNINGS " )
else()
	# clan + g++ specific settings
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-deprecated-declarations -Wno-ignored-attributes")
endif()

#----------------
# OPEN MP SUPPORT
#----------------
find_package(OpenMP)
if(OPENMP_FOUND)
	message(STATUS "Building with OpenMP support")
	
	if(USE_MSCV_EXPERIMENTAL_OPENMP)
		set(OpenMP_C_FLAGS "-openmp:experimental")
		set(OpenMP_CXX_FLAGS "-openmp:experimental")
	endif()
	
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_C_FLAGS}")
	set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${OpenMP_EXE_LINKER_FLAGS}")
	link_libraries(${OpenMP_CXX_LIBRARIES})	
endif()
