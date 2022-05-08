#-----------------------
# detect compiler family
#-----------------------

# first make sure that all compiler types are marked disabled
set(USE_CLANG_COMPILER OFF)
set(USE_GNU_COMPILER OFF)
set(USE_MSVC_COMPILER OFF)
set(USE_BCB_COMPILER OFF)

# then activate the compiler that is actually used
if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
	fwmessage(STATUS "Compiler is CLANG")
	set(USE_CLANG_COMPILER ON)
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "Embarcadero")
	fwmessage(STATUS "Compiler is BCB")
	set(USE_BCB_COMPILER ON)	
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
	fwmessage(STATUS "Compiler is GNU")
	set(USE_GNU_COMPILER ON)
elseif (CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
	fwmessage(STATUS "Compiler is MSVC")
	set(USE_MSVC_COMPILER ON)
else()
	message(WARNING "calling fwmacros.cmake for unknown compiler")
	message(WARNING "you need to edit fwcompiler.cmake")
endif()

#--------------------------
# Global options

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

#--------------------------
# Compiler specific options

# MSVC Compiler specific options
if(USE_MSVC_COMPILER)
	#OPTION (MSVC_USE_EXPERIMENTAL_OPENMP "use the MSVC --openmp:experimental clause" ON)
	
	set(MSVC_WARNING_LEVEL "3" CACHE STRING "Compiler warning reporting level")
	set_property(CACHE MSVC_WARNING_LEVEL PROPERTY STRINGS 0 1 2 3 4 all)
	
	OPTION (MSVC_PARALLEL_COMPILATION "Use parallel compilation" ON)
endif()


# Embarcadero BCB Compiler specific options
if(USE_BCB_COMPILER)
	
endif()

# CLANG Compiler specific options
if(USE_CLANG_COMPILER)
	# select stdlib
	set(CLANG_STDLIB "default" CACHE STRING "Select the version of the C++ STL to be used")
	set_property(CACHE CLANG_STDLIB PROPERTY STRINGS default libc++ stdlibc++)	

	OPTION( USE_Werror "Treat warnings as errors -Werror" OFF)
	OPTION( USE_Wall "Use -Wall" ON)
	OPTION( USE_Wextra "Use -Wextra" OFF)
	OPTION( USE_Wpedantic "Use -Wpedantic" OFF)
	OPTION( USE_Wthreadsafety "Use -Wthread-safety" OFF)

	OPTION( CLANG_LINKTIME_OPTIMIZATION "Activate GNU link time optimization (warning slow)" OFF)

	set(CLANG_ARCHITECTURE "native" CACHE STRING "Compile for CPU architecture")
	OPTION (CLANG_STATIC_ANALYSIS "Use the clang static analyzer" OFF)
	
	OPTION (CLANG_USE_TIDY "Use clang-tidy" OFF)
	
	# clang sanitizers
	set(CLANG_SANITIZER "none" CACHE STRING "Compiler with clang sanitizer active")
	set_property(CACHE CLANG_SANITIZER PROPERTY STRINGS none thread address memory undefined leak safe-stack)	
	
	if(CLANG_STATIC_ANALYSIS)
		set(CLANG_STATIC_ANALYSIS_DIR "" CACHE STRING "Where to put the clang statioc analysis output files")
	endif()
	
	OPTION( GENERATE_COMPILE_COMMANDS "generate compile_commands.json" ON)
	
	if(GENERATE_COMPILE_COMMANDS)
		set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
	endif()
	
	if(CLANG_USE_TIDY)	
		set(CMAKE_CXX_CLANG_TIDY "clang-tidy;-header-filter=.;-checks=*;--use-color")
	endif()
	
	# target debugger
	set(CLANG_TARGET_DEBUGGER "none" CACHE STRING "Generate debug inforation optrimized for debugger")
	set_property(CACHE CLANG_TARGET_DEBUGGER PROPERTY STRINGS none default gdb lldb sce dbx)
	
	#additional compiler arguments
	set(CLANG_ADDITIONAL_ARGUMENTS "" CACHE PATH "Additional commandline arguments for clang compiler")
endif()

# GNU Compiler specific options
if(USE_GNU_COMPILER)
	OPTION( USE_Werror "Treat warnings as errors -Werror" OFF)
	OPTION( USE_Wall "Use -Wall" ON)
	OPTION( USE_Wextra "Use -Wextra" ON)
	OPTION( USE_Wpedantic "Use -Wpedantic" ON)
	
	OPTION( GNU_LINKTIME_OPTIMIZATION "Activate GNU link time optimization (warning slow)" OFF)
endif()

# -------------------
# Configure SIMD mode
# -------------------
if( SIMD_MODE STREQUAL "SIMD_SSE" )
 set(USE_SSE ON)
 fwmessage(STATUS "Using SIMD mode SSE")
elseif( SIMD_MODE STREQUAL "SIMD_SSE2" )
 set(USE_SSE2 ON)
 fwmessage(STATUS "Using SIMD mode SSE2")
elseif( SIMD_MODE STREQUAL "SIMD_AVX" )
 set(USE_AVX ON)
 fwmessage(STATUS "Using SIMD mode AVX")
elseif( SIMD_MODE STREQUAL "SIMD_AVX2" )
 set(USE_AVX2 ON)
 fwmessage(STATUS "Using SIMD mode AVX2")
elseif( SIMD_MODE STREQUAL "SIMD_AVX512" )
 set(USE_AVX512 ON)
 fwmessage(STATUS "Using SIMD mode AVX512")
else()
 fwmessage(WARNING "Using SIMD mode UNKNOWN")
endif()

#------------------------------------------------------
# macro for setting compiler config for specific target
#------------------------------------------------------

macro(set_target_cxx_config)
	set(options )
    set(oneValueArgs TARGET )
    set(multiValueArgs )
    cmake_parse_arguments(P "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

	# set language standard (if compiler if NOT BCB)
	if(NOT USE_BCB_COMPILER)
		target_compile_features(${P_TARGET} PRIVATE ${CXX_COMPILER_STANDARD})
	endif()
	
	# create debug libraries with 'd' postfix
	set_property(TARGET ${P_TARGET} PROPERTY DEBUG_POSTFIX d)	

	# handle open MP
	if(USE_OPENMP)
		find_package(OpenMP)
		if(OPENMP_FOUND)
			fwmessage(STATUS "Building with OpenMP support")
					
			target_include_directories(${P_TARGET} PUBLIC ${OpenMP_CXX_INCLUDE_DIRS})
			target_link_libraries(${P_TARGET} PUBLIC ${OpenMP_CXX_LIBRARIES})
				
			target_compile_options(${P_TARGET} PUBLIC ${OpenMP_CXX_FLAGS})
			target_link_options(${P_TARGET} PUBLIC ${OpenMP_EXE_LINKER_FLAGS})
					
			set_target_properties(${P_TARGET} PROPERTIES CMAKE_CXX_FLAGS ${OpenMP_CXX_FLAGS})
			target_compile_options(${P_TARGET} PUBLIC ${OpenMP_CXX_INCLUDE_DIRS})				
		endif()
	else()
		fwmessage(STATUS "Building without OpenMP support")
	endif()


	# ---------------------------
	# MSVC Compiler configuration
	if(USE_MSVC_COMPILER)
		# debug
		if(OPTIMIZATION_LEVEL_DEBUG STREQUAL "O0")
			target_compile_options(${P_TARGET} PUBLIC $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CONFIG:DEBUG>>:/MDd /Zi /RTC1 /Od /Ob0>)
		elseif(OPTIMIZATION_LEVEL_DEBUG STREQUAL "O1")
			target_compile_options(${P_TARGET} PUBLIC $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CONFIG:DEBUG>>:/MDd /Zi /RTC1 /O1 /Ob1>)			
		else()
			target_compile_options(${P_TARGET} PUBLIC $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CONFIG:DEBUG>>:/MDd /Zi /RTC1 /O2 /Ob2>)
			set(CMAKE_CXX_FLAGS_DEBUG "/MDd /Zi /RTC1 /O2 /Ob2")
		endif()
	
		# release
		if(OPTIMIZATION_LEVEL_RELEASE STREQUAL "O0")
			target_compile_options(${P_TARGET} PUBLIC $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CONFIG:RELEASE>>:/MD /DNDEBUG /Od /Ob0>)
			target_compile_options(${P_TARGET} PUBLIC $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CONFIG:RELWITHDEBINFO>>:/MD /DNDEBUG /Od /Ob0>)		
		elseif(OPTIMIZATION_LEVEL_RELEASE STREQUAL "O1")
			target_compile_options(${P_TARGET} PUBLIC $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CONFIG:RELEASE>>:/MD /DNDEBUG /O1 /Ob1>)
			target_compile_options(${P_TARGET} PUBLIC $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CONFIG:RELWITHDEBINFO>>:/MD /DNDEBUG /O1 /Ob1>)				
		else()
			target_compile_options(${P_TARGET} PUBLIC $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CONFIG:RELEASE>>:/MD /DNDEBUG /O2 /Ob2 /Oi /Ot>)
			target_compile_options(${P_TARGET} PUBLIC $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CONFIG:RELWITHDEBINFO>>:/MD /DNDEBUG /O2 /Ob2 /Oi /Ot>)
		endif()
		
		# enable RTTI
		#target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:/GR}>)	
		
		# warning level
		target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:/W${MSVC_WARNING_LEVEL}>)	
		
		# remove logo
		target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:/nologo>)	
		
		# parallel compilation
		if(MSVC_PARALLEL_COMPILATION)
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:/MP>)
		endif()
		
		# fast math
		if(USE_FAST_MATH)
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:/fp:fast>)
		else()
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:/fp:precise>)
		endif()
		
		# SIMD settings
		if(USE_SSE)
			fwmessage(STATUS "Building with SSE SIMD code generation")
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:/arch:SSE>)		
		elseif(USE_SSE2)
			fwmessage(STATUS "Building with SSE2 SIMD code generation")
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:/arch:SSE2>)
		elseif(USE_AVX)
			fwmessage(STATUS "Building with AVX SIMD code generation")
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:/arch:AVX>)
		elseif(USE_AVX2)
			fwmessage(STATUS "Building with AVX2 SIMD code generation")
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:/arch:AVX2>)
		elseif(USE_AVX512)
			fwmessage(STATUS "Building with AVX512 SIMD code generation")
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:/arch:AVX512>)		
		endif()	
		
		# disable anoying CRT warnings
		target_compile_definitions(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:_CRT_SECURE_NO_WARNINGS>)
		
		# If using MSVC the set the debug database filename
		set_property(TARGET ${P_TARGET} PROPERTY COMPILE_PDB_NAME_DEBUG "${P_TARGET}d")
		set_property(TARGET ${P_TARGET} PROPERTY COMPILE_PDB_NAME_RELWITHDEBINFO "${P_TARGET}")		
		
		# set position independent output
		set_target_properties(${P_TARGET} PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS ON)
	endif()
	
	# ---------------------------
	# BCB Compiler configuration
	if(USE_BCB_COMPILER)
		# Optimizations
		target_compile_options(${P_TARGET} PUBLIC $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CONFIG:DEBUG>>:-${OPTIMIZATION_LEVEL_DEBUG}>)
		target_compile_options(${P_TARGET} PUBLIC $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CONFIG:RELEASE>>:-${OPTIMIZATION_LEVEL_RELEASE}>)
					
		# SIMD settings
		if(USE_SSE)
			fwmessage(STATUS "Building with SSE SIMD code generation")
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-msse>)
		elseif(USE_SSE2)
			fwmessage(STATUS "Building with SSE2 SIMD code generation")
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-msse2>)
		elseif(USE_AVX)
			fwmessage(STATUS "Building with AVX SIMD code generation")
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-mavx>)
		elseif(USE_AVX2)
			fwmessage(STATUS "Building with AVX2 SIMD code generation")
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-mavx -mavx2 -mfma>)
		elseif(USE_AVX512)
			fwmessage(STATUS "Building with AVX512 SIMD code generation")
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-mavx512>)
		endif()	

		# add additional commenline arguments
		target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:${CLANG_ADDITIONAL_ARGUMENTS}>)	
		
		if(USE_BCB_COMPILER)
			# set_embt_target(“DynamicRuntime”)
		endif()
	endif()
	
	
	# ---------------------------
	# CLANG Compiler configuration
	if(USE_CLANG_COMPILER)
		# Optimizations
		target_compile_options(${P_TARGET} PUBLIC $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CONFIG:DEBUG>>:-${OPTIMIZATION_LEVEL_DEBUG}>)
		target_compile_options(${P_TARGET} PUBLIC $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CONFIG:RELEASE>>:-${OPTIMIZATION_LEVEL_RELEASE}>)
		
		if(${CLANG_TARGET_DEBUGGER} STREQUAL "default")
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-g>)
		elseif(${CLANG_TARGET_DEBUGGER} STREQUAL "none")			
		else()
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-g${CLANG_TARGET_DEBUGGER}>)
		endif()
		# fast math
		if(USE_FAST_MATH)
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-ffast-math>)
		endif()

		target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-fno-omit-frame-pointer>)
		target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wno-deprecated-declarations>)
		target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wno-ignored-attributes>)


		if(NOT "${CLANG_STDLIB}" STREQUAL "default")
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-stdlib=${CLANG_STDLIB}>)
		endif()
		
			
		# Warnings
		if(USE_Werror)
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Werror>)
		endif()		
		if(USE_Wall)
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wall>)
		endif()		
		if(USE_Wextra)
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wextra>)
		endif()		
		if(USE_Wpedantic)
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wpedantic>)
		endif()		
		if(USE_Wthreadsafety)
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wthread-safety>)
		endif()
			
		# link time optimization
		if(CLANG_LINKTIME_OPTIMIZATION)
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-flto=thin>)
			target_link_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-flto=thin>)
		endif()
			
		# set architecture
		target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-march=${CLANG_ARCHITECTURE}>)
			
		if(CLANG_STATIC_ANALYSIS)
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:--analyze -Xanalyzer -analyzer-output=text>)
			if(NOT "${CLANG_STATIC_ANALYSIS_DIR}" STREQUAL "")
				target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-o ${CLANG_STATIC_ANALYSIS_DIR}>)
			endif()
		endif()
			
		if(NOT ${CLANG_SANITIZER} STREQUAL "none")
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-fsanitize=${CLANG_SANITIZER}>)
		endif()		
				
		# SIMD settings
		if(USE_SSE)
			fwmessage(STATUS "Building with SSE SIMD code generation")
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-msse>)
		elseif(USE_SSE2)
			fwmessage(STATUS "Building with SSE2 SIMD code generation")
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-msse2>)
		elseif(USE_AVX)
			fwmessage(STATUS "Building with AVX SIMD code generation")
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-mavx>)
		elseif(USE_AVX2)
			fwmessage(STATUS "Building with AVX2 SIMD code generation")
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-mavx -mavx2 -mfma>)
		elseif(USE_AVX512)
			fwmessage(STATUS "Building with AVX512 SIMD code generation")
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-mavx512>)
		endif()	

		# add additional commenline arguments
		target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:${CLANG_ADDITIONAL_ARGUMENTS}>)		
	endif()

	# ---------------------------
	# GNU Compiler configuration
	if(USE_GNU_COMPILER)
		# Optimizations
		target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-${OPTIMIZATION_LEVEL_RELEASE}>)

		# fast math
		if(USE_FAST_MATH)
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-ffast-math>)
		endif()

		target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-fno-omit-frame-pointer>)
		target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wno-deprecated-declarations>)
		target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wno-ignored-attributes>)

		# Warnings
		if(USE_Werror)
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Werror>)
		endif()		
		if(USE_Wall)
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wall>)
		endif()		
		if(USE_Wextra)
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wextra>)
		endif()		
		if(USE_Wpedantic)
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-Wpedantic>)
		endif()			
		
		if(GNU_LINKTIME_OPTIMIZATION)		
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-flto>)
			target_link_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-flto>)
		endif()
		
		# copy c++ flags to C
		set(CMAKE_C_FLAGS ${CMAKE_CXX_FLAGS})
		
		# SIMD settings
		if(USE_SSE)
			fwmessage(STATUS "Building with SSE SIMD code generation")
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-msse>)
		elseif(USE_SSE2)
			fwmessage(STATUS "Building with SSE2 SIMD code generation")
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-msse2>)
		elseif(USE_AVX)
			fwmessage(STATUS "Building with AVX SIMD code generation")
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-mavx>)
		elseif(USE_AVX2)
			fwmessage(STATUS "Building with AVX2 SIMD code generation")
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-mavx -mavx2 -mfma>)
		elseif(USE_AVX512)
			fwmessage(STATUS "Building with AVX512 SIMD code generation")
			target_compile_options(${P_TARGET} PUBLIC $<$<COMPILE_LANGUAGE:CXX>:-mavx512>)
		endif()
	endif()	
endmacro()





