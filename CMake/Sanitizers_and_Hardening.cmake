option(GDCM_SANITIZER_ASAN     "This enables ASan (address sanitizer)" OFF)
option(GDCM_SANITIZER_UBSAN    "This enables UBSan (undefined behavior sanitizer); this is generally compatible with ASan, i.e. can be used concurrently" OFF)
option(GDCM_SANITIZER_MSAN     "This enables MSan (memory sanitizer); not compatible with the other sanitizers" OFF)
option(GDCM_SANITIZER_TSAN     "This enables TSan (thread sanitizer); not compatible with the other sanitizers" OFF)
option(GDCM_LINK_LIBCXX        "Link against libc++ and libc++abi instead of libstdc++!" OFF)
option(GDCM_LINK_STATIC_LIBCXX "Link STATICALLY against libc++ and libc++abi instead of libstdc++! (implies GDCM_LINK_LIBCXX)" OFF)
option(GDCM_HARDENING          "This is enables _GLIBCXX_ASSERTIONS (with GCC) and libc++ hardening modes (with Clang; https://libcxx.llvm.org/Hardening.html)" OFF)
option(GDCM_SUPPRESS_SANITIZER_POSTFIX "This suppresses the postfix that gets used when any sanitizers are enabled" OFF)
option(GDCM_SUPPRESS_SANITIZER_DEFAULT_COMPILE_OPTIONS "This suppresses sanitizer default options when GDCM_SANITIZERS_TO_USE is given" OFF)
option(GDCM_SUPPRESS_SANITIZER_LINK_STATIC_LIBCXX "This is an escape hatch to suppress use of libc++ in favor of libstdc++ (which is otherwise the default). Use with great care!" OFF)
mark_as_advanced(GDCM_SANITIZER_ASAN GDCM_SANITIZER_UBSAN GDCM_SANITIZER_MSAN GDCM_SANITIZER_TSAN GDCM_LINK_LIBCXX GDCM_LINK_STATIC_LIBCXX GDCM_HARDENING GDCM_SUPPRESS_SANITIZER_POSTFIX GDCM_SUPPRESS_SANITIZER_DEFAULT_COMPILE_OPTIONS GDCM_SUPPRESS_SANITIZER_LINK_STATIC_LIBCXX)
# GDCM_OVERRIDE_SANITIZER_OPTLVL
# GDCM_OVERRIDE_HARDENING_MODE

set(GDCM_DEFAULT_SANITIZER_COMPILE_OPTIONS "-fno-omit-frame-pointer;-fno-optimize-sibling-calls")
if (DEFINED GDCM_SANITIZERS_TO_USE)
  # Rule out incompatible options
  if (GDCM_SANITIZER_ASAN OR GDCM_SANITIZER_MSAN OR GDCM_SANITIZER_TSAN OR GDCM_SANITIZER_UBSAN)
    if (DEFINED GDCM_SANITIZER_COMPILE_OPTIONS)
      message(FATAL_ERROR "When giving GDCM_SANITIZERS_TO_USE and GDCM_SANITIZER_COMPILE_OPTIONS on the command line, it is an error to use SANITIZER_* options, too!")
    else()
      message(FATAL_ERROR "When giving GDCM_SANITIZERS_TO_USE on the command line, it is an error to use SANITIZER_* options, too!")
    endif()
  endif()
  # If given, append the user-provided sanitizer compile options to the default ones (GDCM_DEFAULT_SANITIZER_COMPILE_OPTIONS) unless GDCM_SUPPRESS_SANITIZER_DEFAULT_COMPILE_OPTIONS is set
  if (DEFINED GDCM_SANITIZER_COMPILE_OPTIONS)
    if (NOT GDCM_SUPPRESS_SANITIZER_DEFAULT_COMPILE_OPTIONS)
      if (",${GDCM_SANITIZERS_TO_USE}," MATCHES ",address,")
        set(GDCM_SANITIZER_COMPILE_OPTIONS "${GDCM_DEFAULT_SANITIZER_COMPILE_OPTIONS};-fsanitize-address-use-after-return=runtime;-fsanitize-address-use-after-scope;${GDCM_SANITIZER_COMPILE_OPTIONS}")
      else()
        set(GDCM_SANITIZER_COMPILE_OPTIONS "${GDCM_DEFAULT_SANITIZER_COMPILE_OPTIONS};${GDCM_SANITIZER_COMPILE_OPTIONS}")
      endif()
      message(VERBOSE "Appending your GDCM_SANITIZER_COMPILE_OPTIONS to the default ones (enable GDCM_SUPPRESS_SANITIZER_DEFAULT_COMPILE_OPTIONS to suppress!):")
      message(VERBOSE "    GDCM_SANITIZER_COMPILE_OPTIONS=${GDCM_SANITIZER_COMPILE_OPTIONS}")
    else()
      message(VERBOSE "Suppressing sanitizer default compile options at your request.")
    endif()
  else() # ... otherwise apply the defaults, distinguishing between defaults where ASan is involved and others
    if (NOT GDCM_SUPPRESS_SANITIZER_DEFAULT_COMPILE_OPTIONS)
      message(VERBOSE "Sanitizer names overridden by GDCM_SANITIZERS_TO_USE, but no GDCM_SANITIZER_COMPILE_OPTIONS were given. Using defaults (enable GDCM_SUPPRESS_SANITIZER_DEFAULT_COMPILE_OPTIONS to suppress!):")
      if (",${GDCM_SANITIZERS_TO_USE}," MATCHES ",address,")
        set(GDCM_SANITIZER_COMPILE_OPTIONS "${GDCM_DEFAULT_SANITIZER_COMPILE_OPTIONS};-fsanitize-address-use-after-return=runtime;-fsanitize-address-use-after-scope")
      else()
        set(GDCM_SANITIZER_COMPILE_OPTIONS "${GDCM_DEFAULT_SANITIZER_COMPILE_OPTIONS}")
      endif()
      message(VERBOSE "    GDCM_SANITIZER_COMPILE_OPTIONS=${GDCM_SANITIZER_COMPILE_OPTIONS}")
    else()
      message(VERBOSE "Suppressing sanitizer default compile options at your request.")
    endif()
  endif()
else()
  set(GDCM_SANITIZERS_TO_USE "")
  set(GDCM_SANITIZER_COMPILE_OPTIONS "")
  # Figure out the requested sanitizer settings
  if ((GDCM_SANITIZER_ASAN OR GDCM_SANITIZER_UBSAN) AND (GDCM_SANITIZER_MSAN OR GDCM_SANITIZER_TSAN))
    message(FATAL_ERROR "ASan and UBSan can be used concurrently with each other, but not with other sanitizers (ASan=${GDCM_SANITIZER_ASAN}, UBSan=${GDCM_SANITIZER_UBSAN}, MSan=${GDCM_SANITIZER_MSAN}, TSan=${GDCM_SANITIZER_TSAN})")
  elseif (GDCM_SANITIZER_MSAN AND GDCM_SANITIZER_TSAN) # MSan AND TSan is an error
    message(FATAL_ERROR "You asked to enable MSan _and_ TSan, but they cannot be used concurrently!")
  elseif (GDCM_SANITIZER_ASAN AND GDCM_SANITIZER_UBSAN) # both: ASan and UBSan
    message(VERBOSE "Enabling instrumentation with Address Sanitizer (ASan) AND Undefined Behavior Sanitizer (UBSan) ...")
    set(GDCM_SANITIZERS_TO_USE "address,undefined")
    set(GDCM_SANITIZER_COMPILE_OPTIONS "${GDCM_DEFAULT_SANITIZER_COMPILE_OPTIONS};-fsanitize-address-use-after-return=runtime;-fsanitize-address-use-after-scope")
  elseif (GDCM_SANITIZER_ASAN AND NOT GDCM_SANITIZER_UBSAN) # ASan alone
    message(VERBOSE "Enabling instrumentation with Address Sanitizer (ASan)" ...)
    set(GDCM_SANITIZERS_TO_USE "address")
    set(GDCM_SANITIZER_COMPILE_OPTIONS "${GDCM_DEFAULT_SANITIZER_COMPILE_OPTIONS};-fsanitize-address-use-after-return=runtime;-fsanitize-address-use-after-scope")
  elseif (GDCM_SANITIZER_UBSAN AND NOT GDCM_SANITIZER_ASAN) # UBSan alone
    message(VERBOSE "Enabling instrumentation with Undefined Behavior Sanitizer (UBSan)" ...)
    set(GDCM_SANITIZERS_TO_USE "undefined")
    set(GDCM_SANITIZER_COMPILE_OPTIONS "${GDCM_DEFAULT_SANITIZER_COMPILE_OPTIONS}")
  elseif (GDCM_SANITIZER_MSAN) # MSan alone
    message(VERBOSE "Enabling instrumentation with Memory Sanitizer (MSan)" ...)
    set(GDCM_SANITIZERS_TO_USE "memory")
    set(GDCM_SANITIZER_COMPILE_OPTIONS "${GDCM_DEFAULT_SANITIZER_COMPILE_OPTIONS}")
  elseif (GDCM_SANITIZER_TSAN) # TSan alone
    message(VERBOSE "Enabling instrumentation with Thread Sanitizer (TSan)" ...)
    set(GDCM_SANITIZERS_TO_USE "thread")
  endif()
endif()
set(GDCM_SANITIZER_POSTFIX)
if (NOT GDCM_SANITIZERS_TO_USE STREQUAL "")
  if(NOT GDCM_SUPPRESS_SANITIZER_POSTFIX)
    set(GDCM_SANITIZER_POSTFIX "_sanitize.${GDCM_SANITIZERS_TO_USE}")
    string(REPLACE "," "_" GDCM_SANITIZER_POSTFIX "${GDCM_SANITIZER_POSTFIX}")
  endif()
  if (CMAKE_CROSSCOMPILING)
    message(FATAL_ERROR "Sanitizers cannot be used while cross-compiling, for the time being!")
  endif()
  if (NOT CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    message(FATAL_ERROR "Sanitizers can only be used with Clang and libc++ for the time being!")
  endif()
  if (NOT GDCM_SUPPRESS_SANITIZER_LINK_STATIC_LIBCXX)
    set(GDCM_LINK_STATIC_LIBCXX ON CACHE BOOL "When enabling sanitizers we force the statically linked libc++" FORCE)
  endif()
  if (GDCM_SANITIZER_COMPILE_OPTIONS STREQUAL "")
    add_compile_options(-fsanitize=${GDCM_SANITIZERS_TO_USE})
  else()
    add_compile_options(-fsanitize=${GDCM_SANITIZERS_TO_USE} ${GDCM_SANITIZER_COMPILE_OPTIONS})
  endif()
  if (SANITIZER_LINK_OPTIONS STREQUAL "")
    add_link_options(-fsanitize=${GDCM_SANITIZERS_TO_USE})
  else()
    add_link_options(-fsanitize=${GDCM_SANITIZERS_TO_USE} ${SANITIZER_LINK_OPTIONS})
  endif()
  add_link_options(-shared-libsan)
  execute_process(
    COMMAND ${CMAKE_CXX_COMPILER} -print-target-triple 2> /dev/null
    OUTPUT_VARIABLE
      CLANG_TARGET_TRIPLE
    RESULT_VARIABLE
      CLANG_TARGET_TRIPLE_EXITCODE
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  if (CLANG_TARGET_TRIPLE_EXITCODE EQUAL 0 AND DEFINED CLANG_TARGET_TRIPLE)
    if (CLANG_TARGET_TRIPLE STREQUAL "x86_64-pc-linux-gnu")
      set(_ASAN_DSO_FILENAME "libclang_rt.asan-x86_64.so")
      execute_process(
        COMMAND ${CMAKE_CXX_COMPILER} -print-file-name=${_ASAN_DSO_FILENAME}
        OUTPUT_VARIABLE
          CLANG_ASAN_DSO
        RESULT_VARIABLE
          CLANG_ASAN_DSO_EXITCODE
        OUTPUT_STRIP_TRAILING_WHITESPACE
      )
      if (CLANG_ASAN_DSO_EXITCODE EQUAL 0 AND NOT CLANG_ASAN_DSO STREQUAL "${_ASAN_DSO_FILENAME}")
        get_filename_component(SANITIZER_RPATH "${CLANG_ASAN_DSO}" DIRECTORY)
        message(STATUS "Setting SANITIZER_RPATH=${SANITIZER_RPATH}")
      endif()
    else()
      message(WARNING "Found target triple (CLANG_TARGET_TRIPLE=${CLANG_TARGET_TRIPLE}) not usable for setting rpath")
    endif()
  else()
    message(WARNING "Target triple could not be determined (exit code: ${CLANG_TARGET_TRIPLE_EXITCODE})")
  endif()
  if(DEFINED GDCM_OVERRIDE_SANITIZER_OPTLVL AND GDCM_OVERRIDE_SANITIZER_OPTLVL MATCHES "^[0-3]$")
    message(VERBOSE "Overriding optimization level _with_ sanitizer instrumentation to be: ${GDCM_OVERRIDE_SANITIZER_OPTLVL}")
  else()
    set(GDCM_OVERRIDE_SANITIZER_OPTLVL "1")
    message(VERBOSE "Defaulting optimization level _with_ sanitizer instrumentation to be: ${GDCM_OVERRIDE_SANITIZER_OPTLVL}")
  endif()
  # Environment variables affecting runtime behavior: https://github.com/google/sanitizers/wiki/AddressSanitizerFlags
  set(CMAKE_CXX_FLAGS_DEBUG "-O${GDCM_OVERRIDE_SANITIZER_OPTLVL}") # default would be '-g', but we set -g3 below (look for DWARF_SPLITTING)
  set(CMAKE_C_FLAGS_DEBUG "-O${GDCM_OVERRIDE_SANITIZER_OPTLVL}") # -"-
  set(CMAKE_CXX_FLAGS_RELEASE "-O${GDCM_OVERRIDE_SANITIZER_OPTLVL} -DNDEBUG") # can't have -O3 here
  set(CMAKE_C_FLAGS_RELEASE "-O${GDCM_OVERRIDE_SANITIZER_OPTLVL} -DNDEBUG") # -"-
  # NB: since we are overriding CMAKE_CONFIGURATION_TYPES there is no need to parrot this for CMAKE_CXX_FLAGS_MINSIZEREL and CMAKE_CXX_FLAGS_RELWITHDEBINFO
else()
  set(CMAKE_CXX_FLAGS_DEBUG "") # default would be '-g', but we set -g3 below (look for DWARF_SPLITTING)
  set(CMAKE_C_FLAGS_DEBUG "") # -"-
endif()

if (GDCM_LINK_LIBCXX OR GDCM_LINK_STATIC_LIBCXX)
  if (GDCM_SUPPRESS_SANITIZER_LINK_STATIC_LIBCXX)
    message(FATAL_ERROR "GDCM_SUPPRESS_SANITIZER_LINK_STATIC_LIBCXX=${GDCM_SUPPRESS_SANITIZER_LINK_STATIC_LIBCXX} was explicitly given. This clashes with GDCM_LINK_LIBCXX=${GDCM_LINK_LIBCXX} and/or GDCM_LINK_STATIC_LIBCXX=${GDCM_LINK_STATIC_LIBCXX}.")
  endif()
  if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    if (CMAKE_CXX_FLAGS STREQUAL "")
      set(CMAKE_CXX_FLAGS "-stdlib=libc++")
    else()
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -stdlib=libc++")
    endif()
    if (GDCM_HARDENING)
      if (DEFINED GDCM_OVERRIDE_HARDENING_MODE_DEBUG)
        string(TOUPPER "${GDCM_OVERRIDE_HARDENING_MODE_DEBUG}" GDCM_OVERRIDE_HARDENING_MODE_DEBUG)
        if(NOT GDCM_OVERRIDE_HARDENING_MODE_DEBUG MATCHES "^(none|fast|extensive|debug)$") # Debug config
          set(GDCM_OVERRIDE_HARDENING_MODE_DEBUG "DEBUG")
        endif()
      else()
        set(GDCM_OVERRIDE_HARDENING_MODE_DEBUG "DEBUG")
      endif()
      if (DEFINED GDCM_OVERRIDE_HARDENING_MODE_RELEASE)
        string(TOUPPER "${GDCM_OVERRIDE_HARDENING_MODE_RELEASE}" GDCM_OVERRIDE_HARDENING_MODE_RELEASE)
        if (NOT GDCM_OVERRIDE_HARDENING_MODE_RELEASE MATCHES "^(none|fast|extensive|debug)$") # Release config
          set(GDCM_OVERRIDE_HARDENING_MODE_DEBUG "EXTENSIVE") # deemed a production mode
        endif()
      else()
        set(GDCM_OVERRIDE_HARDENING_MODE_RELEASE "EXTENSIVE") # deemed a production mode
      endif()
      if(DEFINED GDCM_OVERRIDE_HARDENING_MODE) # this overrides the individual modes, if they happen to be set individually
        string(TOUPPER "${GDCM_OVERRIDE_HARDENING_MODE}" GDCM_OVERRIDE_HARDENING_MODE)
        if(GDCM_OVERRIDE_HARDENING_MODE MATCHES "^(none|fast|extensive|debug)$") # both at once
          set(GDCM_OVERRIDE_HARDENING_MODE_DEBUG "${GDCM_OVERRIDE_HARDENING_MODE}")
          set(GDCM_OVERRIDE_HARDENING_MODE_RELEASE "${GDCM_OVERRIDE_HARDENING_MODE}")
        endif()
      endif()
      add_compile_definitions(
        $<$<AND:$<CONFIG:Debug>,$<COMPILE_LANGUAGE:CXX>>:_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_${GDCM_OVERRIDE_HARDENING_MODE_DEBUG}>
        $<$<AND:$<CONFIG:Release>,$<COMPILE_LANGUAGE:CXX>>:_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_${GDCM_OVERRIDE_HARDENING_MODE_RELEASE}>
      )
    endif()
  else()
    message(FATAL_ERROR "Linking libc++ is only supported with Clang for the time being!")
  endif()
else()
  if (GDCM_HARDENING AND CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    string(REGEX MATCH "[0-9]+" GXX_VERSION_MAJOR ${CMAKE_CXX_COMPILER_VERSION})
    if (GXX_VERSION_MAJOR LESS 14)
      add_compile_definitions(
        $<$<AND:$<CONFIG:Debug>,$<COMPILE_LANGUAGE:CXX>>:_GLIBCXX_ASSERTION>
      )
    elseif()
      add_compile_options(
        $<$<CONFIG:Debug>:-fhardened -Whardened> # implies -D_GLIBCXX_ASSERTION for C++
      )
    endif()
  else()
    add_compile_definitions(
      $<$<AND:$<CONFIG:Debug>,$<COMPILE_LANGUAGE:CXX>>:_GLIBCXX_ASSERTION>
    )
  endif()
endif()
if (GDCM_HARDENING)
  add_compile_options( # catch obsolete C constructs
    $<$<COMPILE_LANGUAGE:C>:-Werror=implicit>
    $<$<COMPILE_LANGUAGE:C>:-Werror=incompatible-pointer-types>
    $<$<COMPILE_LANGUAGE:C>:-Werror=int-conversion>
  )
  add_compile_definitions(
    $<$<CONFIG:Debug>:_FORTIFY_SOURCE=3>
  )
endif()
