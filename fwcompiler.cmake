#-----------------------
# detect compiler family
#-----------------------

set(COMPILER_FAMILY "UNKNOWN")

if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  set(COMPILER_FAMILY "CLANG")
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  set(COMPILER_FAMILY "GCC")
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "Intel")
  set(COMPILER_FAMILY "INTEL")
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
  set(COMPILER_FAMILY "MSVC")
endif()

if(COMPILER_FAMILY STREQUAL "UNKNOWN")
	fwmessage(ERROR "Unsupported compiler - edit compiler.cmake to ass support")
else()
	fwmessage(STATUS "Compiler is ${COMPILER_FAMILY}")
endif()


#--------
# options
#--------

# OpenMP
OPTION (USE_OPENMP "Compile with OpenMP" ON)

# Optimizations
set(OPTIMIZATION_LEVEL_RELEASE "O3" CACHE STRING "Compiler optimization level used for release")
set_property(CACHE OPTIMIZATION_LEVEL_RELEASE PROPERTY STRINGS O0 O1 O2 O3)
set(OPTIMIZATION_LEVEL_DEBUG "O0" CACHE STRING "Compiler optimization level used for debug")
set_property(CACHE OPTIMIZATION_LEVEL_DEBUG PROPERTY STRINGS O0 O1 O2 O3)

# fast math
OPTION (USE_FAST_MATH "Compile with fast math" ON)

# SIMD mode
set(SIMD_MODE "SIMD_AVX2" CACHE STRING "SIMD mode to be used by compiler")
set_property(CACHE SIMD_MODE PROPERTY STRINGS SIMD_NONE SIMD_SSE SIMD_SSE2 SIMD_AVX SIMD_AVX2 SIMD_AVX512)

# C++ standard
set(CXX_COMPILER_STANDARD "cxx_std_20" CACHE STRING "C++ language standard")
set_property(CACHE CXX_COMPILER_STANDARD PROPERTY STRINGS cxx_std_98 cxx_std_11 cxx_std_14 cxx_std_17 cxx_std_20 cxx_std_23)

# Copmpiler specific options

if(MSVC)
	OPTION (MSVC_USE_EXPERIMENTAL_OPENMP "use the MSVC --openmp:experimental clause" ON)
	
	set(MSVC_WARNING_LEVEL "3" CACHE STRING "Compiler warning reporting level")
	set_property(CACHE MSVC_WARNING_LEVEL PROPERTY STRINGS 0 1 2 3 4 all)
	
	OPTION (MSVC_PARALLEL_COMPILATION "Use parallel compilation" ON)
endif()

if(COMPILER_FAMILY STREQUAL "CLANG")
	OPTION( CLANG_USE_Werror "Use -Werror" ON)
	OPTION( CLANG_USE_Wall "Use -Wall" ON)
	OPTION( CLANG_USE_Wextra "Use -Wextra" OFF)

	set(CLANG_ARCHITECTURE "native" CACHE STRING "Compile for CPU architecture")
	OPTION (CLANG_STATIC_ANALYSIS "Use the clang static analyzer" OFF)
	
	OPTION( CLANG_SANITIZE_THREAD_SAFETY "Use -Wthread-safety -fsanitize=thread" OFF)
	OPTION( CLANG_SANITIZE_ADDRESS "Use -fsanitize=address" OFF)
	OPTION( CLANG_SANITIZE_MEMORY "Use -fsanitize=memory" OFF)
	OPTION( CLANG_SANITIZE_UNDEFINED "Use -fsanitize=undefined" OFF)
	OPTION( CLANG_SANITIZE_LEAK "Use -fsanitize=leak" OFF)
	OPTION( CLANG_SANITIZE_SAFE_STACK "Use -fsanitize=safe-stack" OFF)	
	
	if(CLANG_STATIC_ANALYSIS)
		set(CLANG_STATIC_ANALYSIS_DIR "" CACHE STRING "Where to put the clang statioc analysis output files")
	endif()
	
	
endif()

# -------------------
# Configure SIMD mode
# -------------------
if( SIMD_MODE STREQUAL "SIMD_SSE" )
 set(USE_SSE TRUE)
 fwmessage(STATUS "Using SIMD mode SSE")
elseif( SIMD_MODE STREQUAL "SIMD_SSE2" )
 set(USE_SSE2 TRUE)
 fwmessage(STATUS "Using SIMD mode SSE2")
elseif( SIMD_MODE STREQUAL "SIMD_AVX" )
 set(USE_AVX TRUE)
 fwmessage(STATUS "Using SIMD mode AVX")
elseif( SIMD_MODE STREQUAL "SIMD_AVX2" )
 set(USE_AVX2 TRUE)
 fwmessage(STATUS "Using SIMD mode AVX2")
elseif( SIMD_MODE STREQUAL "SIMD_AVX512" )
 set(USE_AVX512 TRUE)
 fwmessage(STATUS "Using SIMD mode AVX512")
else()
 fwmessage(WARNING "Using SIMD mode UNKNOWN")
endif()

#----------------
# OPEN MP SUPPORT
#----------------
if(USE_OPENMP)
	find_package(OpenMP)
	if(OPENMP_FOUND)
		fwmessage(STATUS "Building with OpenMP support")
				
		add_compile_options( ${OpenMP_CXX_FLAGS} )
		add_link_options( ${OpenMP_EXE_LINKER_FLAGS} )
				
		if(MSVC_USE_EXPERIMENTAL_OPENMP)
			add_compile_options( "-openmp:experimental" )
		endif()
		
		link_libraries(${OpenMP_CXX_LIBRARIES})	
		include_directories( ${OpenMP_CXX_INCLUDE_DIRS} )				
	endif()
else()
	fwmessage(STATUS "Building without OpenMP support")
endif()


# ---------------------------
# compiler optimization flags
# ---------------------------

# optimization level
if(COMPILER_FAMILY STREQUAL "MSVC")	# windows compilers

	# debug
	if(OPTIMIZATION_LEVEL_DEBUG STREQUAL "O0")
		set(CMAKE_CXX_FLAGS_DEBUG "/MDd /Zi /RTC1 /Od /Ob0")
	elseif(OPTIMIZATION_LEVEL_DEBUG STREQUAL "O1")
		set(CMAKE_CXX_FLAGS_DEBUG "/MDd /Zi /RTC1 /O1 /Ob1")
	else()
		set(CMAKE_CXX_FLAGS_DEBUG "/MDd /Zi /RTC1 /O2 /Ob2")
	endif()
	
	# release
	if(OPTIMIZATION_LEVEL_RELEASE STREQUAL "O0")
		set(CMAKE_CXX_FLAGS_RELEASE "/MD /DNDEBUG /Od /Ob0")
		set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "/MD /DNDEBUG /Od /Ob0")
	elseif(OPTIMIZATION_LEVEL_RELEASE STREQUAL "O1")
		set(CMAKE_CXX_FLAGS_RELEASE "/MD /DNDEBUG /O1 /Ob1")
		set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "/MD /DNDEBUG /O1 /Ob1")	
	else()
		set(CMAKE_CXX_FLAGS_RELEASE "/MD /DNDEBUG /O2 /Ob2 /Oi /Ot")
		set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "/MD /DNDEBUG /O2 /Ob2 /Oi /Ot")		
	endif()
	
	# warning level
	string(APPEND CMAKE_CXX_FLAGS  " /W${MSVC_WARNING_LEVEL}" )
	
	# remove logo
	string(APPEND CMAKE_CXX_FLAGS  " /nologo" )
	
	# parallel compilation
	if(MSVC_PARALLEL_COMPILATION)
		string(APPEND CMAKE_CXX_FLAGS  " /MP" )
	endif()
	
	# fast math
	if(USE_FAST_MATH)
		string(APPEND CMAKE_CXX_FLAGS  " /fp:fast")
	else()
		string(APPEND CMAKE_CXX_FLAGS  " /fp:precise")
	endif()
	
	# SIMD settings
	if(USE_SSE)
		fwmessage(STATUS "Building with SSE SIMD code generation")
		string(APPEND CMAKE_CXX_FLAGS  " /arch:SSE")
	elseif(USE_SSE2)
		fwmessage(STATUS "Building with SSE2 SIMD code generation")
		string(APPEND CMAKE_CXX_FLAGS  " /arch:SSE2")
	elseif(USE_AVX)
		fwmessage(STATUS "Building with AVX SIMD code generation")
		string(APPEND CMAKE_CXX_FLAGS  " /arch:AVX /DINSTRSET=7")		
	elseif(USE_AVX2)
		fwmessage(STATUS "Building with AVX2 SIMD code generation")
		string(APPEND CMAKE_CXX_FLAGS  " /arch:AVX2 /DINSTRSET=8")		
	elseif(USE_AVX512)
		fwmessage(STATUS "Building with AVX512 SIMD code generation")
		string(APPEND CMAKE_CXX_FLAGS  " /arch:AVX512")				
	endif()	
	
	# disable anoying CRT warnings
	string(APPEND CMAKE_CXX_FLAGS  " -D_CRT_SECURE_NO_WARNINGS " )
	
	
else()	# posix compilers

	# Optimizations
	string(APPEND CMAKE_CXX_FLAGS "-${OPTIMIZATION_LEVEL_RELEASE}" )

	# fast math
	if(USE_FAST_MATH)
		string(APPEND CMAKE_CXX_FLAGS  " -ffast-math" )
	endif()

	if(COMPILER_FAMILY STREQUAL "CLANG")
		string(APPEND CMAKE_CXX_FLAGS " -fno-omit-frame-pointer")
		string(APPEND CMAKE_CXX_FLAGS  " -Wno-deprecated-declarations")
		string(APPEND CMAKE_CXX_FLAGS  " -Wno-ignored-attributes")
		#string(APPEND CMAKE_CXX_FLAGS  " -Wno-unused-command-line-argument")
		
		# Warnings
		if(CLANG_USE_Werror)
			string(APPEND CMAKE_CXX_FLAGS  " -Werror")
		endif()		
		if(CLANG_USE_Wall)
			string(APPEND CMAKE_CXX_FLAGS  " -Wall")
		endif()		
		if(CLANG_USE_Wextra)
			string(APPEND CMAKE_CXX_FLAGS  " -Wextra")
		endif()		
		
		# set architecture
		string(APPEND CMAKE_CXX_FLAGS " -march=${CLANG_ARCHITECTURE}")		
		
		if(CLANG_STATIC_ANALYSIS)
			string(APPEND CMAKE_CXX_FLAGS " --analyze -Xanalyzer -analyzer-output=text")
			if(NOT "${CLANG_STATIC_ANALYSIS_DIR}" STREQUAL "")
			string(APPEND CMAKE_CXX_FLAGS " -o ${CLANG_STATIC_ANALYSIS_DIR}")
			endif()
		endif()
		
		if(CLANG_SANITIZE_THREAD_SAFETY)
			string(APPEND CMAKE_CXX_FLAGS " -Wthread-safety -fsanitize=thread")		
		endif()
		if(CLANG_SANITIZE_ADDRESS)
			string(APPEND CMAKE_CXX_FLAGS " -fsanitize=address")		
		endif()
		if(CLANG_SANITIZE_MEMORY)
			string(APPEND CMAKE_CXX_FLAGS " -fsanitize=memory")		
		endif()
		if(CLANG_SANITIZE_UNDEFINED)
			string(APPEND CMAKE_CXX_FLAGS " -fsanitize=undefined")
		endif()
		if(CLANG_SANITIZE_LEAK)
			string(APPEND CMAKE_CXX_FLAGS " -fsanitize=leak")
		endif()
		if(CLANG_SANITIZE_SAFE_STACK)
			string(APPEND CMAKE_CXX_FLAGS " -fsanitize=safe-stack")
		endif()
	endif()
	
	# copy c++ flags to C
	set(CMAKE_C_FLAGS ${CMAKE_CXX_FLAGS})
	
	# SIMD settings
	if(USE_SSE)
		fwmessage(STATUS "Building with SSE SIMD code generation")
		string(APPEND CMAKE_CXX_FLAGS " -msse")		
	elseif(USE_SSE2)
		fwmessage(STATUS "Building with SSE2 SIMD code generation")
		string(APPEND CMAKE_CXX_FLAGS " -msse2")
	elseif(USE_AVX)
		fwmessage(STATUS "Building with AVX SIMD code generation")
		string(APPEND CMAKE_CXX_FLAGS " -mavx")
	elseif(USE_AVX2)
		fwmessage(STATUS "Building with AVX2 SIMD code generation")
		string(APPEND CMAKE_CXX_FLAGS " -mavx -mavx2 -mfma")		
	elseif(USE_AVX512)
		fwmessage(STATUS "Building with AVX512 SIMD code generation")
		string(APPEND CMAKE_CXX_FLAGS  " -mavx512")
	endif()


endif()


# print configuration
fwmessage(STATUS "CMAKE_CXX_FLAGS = ${CMAKE_CXX_FLAGS}")
fwmessage(STATUS "CMAKE_CXX_FLAGS_RELEASE = ${CMAKE_CXX_FLAGS_RELEASE}")
fwmessage(STATUS "CMAKE_CXX_FLAGS_RELWITHDEBINFO = ${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")
fwmessage(STATUS "CMAKE_CXX_FLAGS_DEBUG = ${CMAKE_CXX_FLAGS_DEBUG}")



