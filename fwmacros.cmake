# ====================================
# === fwmacros master include file ===
# ====================================

# macro: fwmessage
#   verbosity macro for std cmake message alllowing control of verbosity
macro(fwmessage _type _text)

    if(FWMACROS_VERBOSE)
        message(${_type} "${_text}")
    endif() 
endmacro()


include(fwmacros_options)		# load std lib options
include(fwmacros_compiler)		# include compiler options
include(fwmacros_utility)		# general helper macros
include(fwmacros_lib)			# create and install libraries
include(fwmacros_exe)			# create and install executables
include(fwmacros_tests)			# generate std unit test modules
include(fwmacros_search)		# search for non package libraries





