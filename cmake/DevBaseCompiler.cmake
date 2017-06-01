if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    message(STATUS "Setting build type to 'Release' as none was specified.")
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build." FORCE)
    # Set the possible values of build type for cmake-gui
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release"
        "MinSizeRel" "RelWithDebInfo")
endif()


if(UNIX AND NOT CYGWIN)
    if(APPLE)
        set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
        set(CMAKE_INSTALL_NAME_DIR "${CMAKE_INSTALL_PREFIX}/lib")
    else()
        set(CMAKE_SKIP_BUILD_RPATH FALSE)
        set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
        set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
        set(CMAKE_INSTALL_RPATH_USE_LINK_PATH FALSE)
    endif()
endif()


include(CheckCXXCompilerFlag)



# Related linking of fern lib to generated C++ code.
# set(CMAKE_SHARED_LINKER_FLAGS "-Wl,--export-all-symbols")
# For executables, you can use:
# ADD_EXECUTABLE(NAME_OF_EXECUTABLE $ $)
# SET(LINK_FLAGS ${LINK_FLAGS} "-Wl,-whole-archive")
# TARGET_LINK_LIBRARIES(NAME_OF_EXECUTABLE ${PROJECT_NAME})




# TODO: Treat all warnings as errors and explicitly turn off warning that
#       we don't consider errors. Example(!):
# Clang:
# -Werror -Weverything -Wno-c++98-compat -Wno-c++98-compat-pedantic -Wno-exit-time-destructors -Wno-missing-braces -Wno-padded
# Visual Studio:
# /WX /Wall
# Gcc:
# -Werror -Wall -Wextra -Wpedantic -Wcast-align -Wcast-qual -Wconversion -Wctor-dtor-privacy -Wdisabled-optimization -Wdouble-promotion -Wfloat-equal -Wformat=2 -Winit-self -Winvalid-pch -Wlogical-op -Wmissing-declarations -Wmissing-include-dirs -Wnoexcept -Wold-style-cast -Woverloaded-virtual -Wredundant-decls -Wshadow -Wsign-conversion -Wsign-promo -Wstrict-null-sentinel -Wstrict-overflow=5 -Wtrampolines -Wundef -Wunsafe-loop-optimizations -Wvector-operation-performance -Wzero-as-null-pointer-constant


if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR
        CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    # Handle case where C++ compiler is gcc or clang.

    # TODO Figure this out:
    # https://gcc.gnu.org/wiki/Visibility

    # The code assumes integer overflow and underflow wraps. This is not
    # guaranteed by the standard. Gcc may assume overflow/underflow will not
    # happen and optimize the code accordingly. That's why we added
    # -fno-strict-overflow. It would be better if we don't assume
    # over/underflow wraps.
    # See http://www.airs.com/blog/archives/120
    # See out of range policy of add algorithm for signed integrals.
    #
    # Add as many warning options as possible/useful:
    # - https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html
    # TODO Maybe add:
    # -Wconversion
    # -Wsign-conversion
    set(CMAKE_CXX_FLAGS
        "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wpedantic -Wcast-qual -Wwrite-strings -Werror=strict-aliasing -fno-strict-overflow -ftemplate-backtrace-limit=0"
    )

    # This results in an error on mingw/gcc 4.8/windows. Some warning about
    # and unused parameters. Skip for now.
    # set(CMAKE_CXX_FLAGS_RELEASE
    #         "${CMAKE_CXX_FLAGS_RELEASE} -Werror"
    #     )

    # if(NOT MINGW)
    #     # This option triggers a warning on Windows, something in
    #     # boost.filesystem. Not fixing it now.
    #     set(CMAKE_CXX_FLAGS
    #         "${CMAKE_CXX_FLAGS} -Wzero-as-null-pointer-constant"
    #     )
    # endif()

    if(APPLE)
        set(CMAKE_CXX_FLAGS
            "${CMAKE_CXX_FLAGS} -Wno-unused-local-typedefs"
        )
    endif()

    # TODO Revisit this option. Only needed for shared libraries.
    # Add the PIC compiler flag if needed.
    # See also CMake property POSITION_INDEPENDENT_CODE.
    if(UNIX AND NOT WIN32)
        if(CMAKE_SIZEOF_VOID_P MATCHES "8")
            CHECK_CXX_COMPILER_FLAG("-fPIC" WITH_FPIC)
            if(WITH_FPIC)
                add_definitions(-fPIC)
            endif()
        endif()
    endif()

elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    # Handle case where C++ compiler is msvc.

    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_SCL_SECURE_NO_WARNINGS /wd4101")

endif()


if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
    # Handle case where C compiler is gcc and not clang.

    set(CMAKE_C_FLAGS
        "${CMAKE_C_FLAGS} -Wall -Wextra -Wpedantic -Wcast-qual -Wwrite-strings -Werror=strict-aliasing -fno-strict-overflow"
        # If you need this, add it to your project's CMakeLists.txt.
        # -Wno-unused-parameter"
    )

    set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -U_FORTIFY_SOURCE")

    # Make linker report any unresolved symbols.
    set(CMAKE_SHARED_LINKER_FLAGS
        "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--no-undefined")
endif()


if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    # Handle case where C++ compiler is gcc and not clang.

    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -U_FORTIFY_SOURCE")

    # Make linker report any unresolved symbols.
    set(CMAKE_SHARED_LINKER_FLAGS
        "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--no-undefined")

elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    # Handle case where C++ compiler is clang and not gcc.

    check_cxx_compiler_flag("-Wno-vla-extension"
        CXX_SUPPORTS_NO_VLA_EXTENSION)

    if (CXX_SUPPORTS_NO_VLA_EXTENSION)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-vla-extension")
    endif ()
endif()


if(WIN32)
    set(CMAKE_DEBUG_POSTFIX "d")
endif()


# Peacock is a project for building external software. It can be used to
# build the Boost libraries on all kinds of platform, for example. A
# PEACOCK_PREFIX CMake variable or environment variable can be set to
# point us to the root of the platform-specific files. By adding the
# current platform string to this prefix, we end up at the root of the
# header files and libraries.
# See also: https://github.com/geoneric/peacock
if(peacock_compiler_found)
    # If the PEACOCK_PREFIX CMake variable is not set, but an environment
    # variable with that name is, then copy it to a CMake variable. This way
    # the CMake variable takes precedence.
    if((NOT DEFINED PEACOCK_PREFIX) AND (DEFINED ENV{PEACOCK_PREFIX}))
        set(PEACOCK_PREFIX $ENV{PEACOCK_PREFIX})
    endif()

    if((DEFINED PEACOCK_PREFIX) AND PEACOCK_PREFIX)
        # PEACOCK_PREFIX takes precedence over all other paths.

        # # if cross compiling:
        # set(CMAKE_FIND_ROOT_PATH
        #     ${PEACOCK_PREFIX}/${peacock_target_platform})
        # else:
        set(CMAKE_PREFIX_PATH
            ${PEACOCK_PREFIX}/${peacock_target_platform}
            ${CMAKE_PREFIX_PATH}
        )
        message(STATUS "Probing Peacock builds in: ${PEACOCK_PREFIX}/${peacock_target_platform}")
        set(CMAKE_INCLUDE_DIRECTORIES_BEFORE TRUE)
    endif()
endif()
