# This script determines the characteristics of the host and target platforms
# and normalizes the names. The resulting variables can be used in the package
# build scripts and in configuring external projects.
# At the bottom is a list of the variables set by this script.
# This script depends on TargetArch script, so when using it to configure
# external projects, make sure to checkout that script as well.
# See the README.md for some more information, including the list of
# normalized names.

# Normalize host system name:
# linux, windows, cygwin
set(host_system_name ${CMAKE_HOST_SYSTEM_NAME})
if(host_system_name STREQUAL "Linux")
    set(host_system_name "linux")
elseif(host_system_name STREQUAL "Darwin")
    set(host_system_name "darwin")
elseif(host_system_name STREQUAL "Windows")
    if(CYGWIN)
        set(host_system_name "cygwin")
    else()
        set(host_system_name "windows")
    endif()
endif()


# Normalize target system name:
# linux, windows, cygwin
set(target_system_name ${CMAKE_SYSTEM_NAME})
if(target_system_name STREQUAL "Linux")
    set(target_system_name "linux")
elseif(target_system_name STREQUAL "Darwin")
    set(target_system_name "darwin")
elseif(target_system_name STREQUAL "Windows")
    if(CYGWIN)
        set(target_system_name "cygwin")
    else()
        set(target_system_name "windows")
    endif()
endif()


if(host_system_name STREQUAL ${target_system_name})
    set(peacock_cross_compiling FALSE)
else()
    set(peacock_cross_compiling TRUE)
endif()


if(CMAKE_CXX_COMPILER_ID)
    set(peacock_compiler_id "${CMAKE_CXX_COMPILER_ID}")
    set(peacock_compiler_version ${CMAKE_CXX_COMPILER_VERSION})
    set(peacock_compiler_found TRUE)
elseif(CMAKE_C_COMPILER_ID)
    set(peacock_compiler_id "${CMAKE_C_COMPILER_ID}")
    set(peacock_compiler_version ${CMAKE_C_COMPILER_VERSION})
    set(peacock_compiler_found TRUE)
endif()


if(peacock_compiler_found)
    # Determine target architecture.
    # https://github.com/petroules/solar-cmake/blob/master/TargetArch.cmake
    include(TargetArch)
    target_architecture(target_architecture)

    # Normalize target architecture:
    # x86_32, x86_64
    if(target_architecture STREQUAL "i386")
        set(target_architecture "x86_32")
    elseif(target_architecture STREQUAL "AMD64")
        set(target_architecture "x86_64")
    endif()

    # Normalize compiler id:
    # clang, gcc, mingw, msvc
    if(peacock_compiler_id STREQUAL "GNU")
        if(MINGW)
            set(peacock_compiler_id "mingw")
        else()
            set(peacock_compiler_id "gcc")
        endif()
    elseif(peacock_compiler_id STREQUAL "MSVC")
        message(${peacock_compiler_id})
        set(peacock_compiler_id "msvc")
    elseif(peacock_compiler_id STREQUAL "Clang")
        set(peacock_compiler_id "clang")
    elseif(peacock_compiler_id STREQUAL "Intel")
        set(peacock_compiler_id "intel")
    else()
        message(FATAL_ERROR "Add compiler id for ${peacock_compiler_id}")
    endif()


    if((peacock_compiler_id STREQUAL "gcc") OR 
            (peacock_compiler_id STREQUAL "mingw") OR
            (peacock_compiler_id STREQUAL "clang"))
        string(FIND ${peacock_compiler_version} "." period_index)
        string(SUBSTRING ${peacock_compiler_version} 0 ${period_index}
            peacock_compiler_main_version)
    elseif(peacock_compiler_id STREQUAL "msvc")
        if(MSVC12)
            # 18.0.21005.1
            set(peacock_compiler_version "12")
            set(peacock_compiler_main_version "12")
        elseif(MSVC14)
            set(peacock_compiler_version "14")
            set(peacock_compiler_main_version "14")
        endif()
    elseif(peacock_compiler_id STREQUAL "intel")
        # e.g.: 17.0.4.20170411
        string(FIND ${peacock_compiler_version} "." period_index)
        string(SUBSTRING ${peacock_compiler_version} 0 ${period_index}
            peacock_compiler_main_version)
    endif()


    # <host>/<target>/<compiler>-<version>/<architecture>
    set(peacock_target_platform ${host_system_name}/${target_system_name}/${peacock_compiler_id}-${peacock_compiler_main_version}/${target_architecture})


    # Set a variable to the host specification as used by some build scripts.
    # In Gcc's terms, host is the same as what is called target here. It is the
    # machine running the software. In Peacock's terminology, host is
    # the machine building the software. Sigh...
    # https://gcc.gnu.org/onlinedocs/gccint/Configure-Terms.html
    #
    # +---------+---------+--------+
    # | Tool    | Builder | Runner |
    # +---------+---------+--------+
    # | Peacock | host    | target |
    # | Gcc     | build   | host   |
    # +---------+---------+--------+

    # See also:
    # - http://www.cmake.org/cmake/help/v3.0/module/GNUInstallDirs.html
    # - https://wiki.debian.org/Multiarch

    if(target_architecture STREQUAL "x86_32")
        if(target_system_name STREQUAL "linux")
            if(peacock_compiler_id STREQUAL "gcc")
                set(peacock_gnu_configure_host "x86_32-unknown-linux")
            elseif(peacock_compiler_id STREQUAL "clang")
                set(peacock_gnu_configure_host "x86_32-unknown-linux")
            else()
                message(FATAL_ERROR "Add GNU configure host")
            endif()
        elseif(target_system_name STREQUAL "windows")
            if(peacock_compiler_id STREQUAL "mingw")
                set(peacock_gnu_configure_host "i686-w64-mingw32")
            else()
                message(FATAL_ERROR "Add GNU configure host")
            endif()
        elseif(target_system_name STREQUAL "cygwin")
            message(FATAL_ERROR "Add GNU configure host")
        else()
            message(FATAL_ERROR "Add GNU configure host")
        endif()
    elseif(target_architecture STREQUAL "x86_64")
        if(target_system_name STREQUAL "linux")
            if(peacock_compiler_id STREQUAL "gcc")
                set(peacock_gnu_configure_host "x86_64-unknown-linux")
            elseif(peacock_compiler_id STREQUAL "clang")
                set(peacock_gnu_configure_host "x86_64-unknown-linux")
            elseif(peacock_compiler_id STREQUAL "intel")
                set(peacock_gnu_configure_host "x86_64-unknown-linux")
            else()
                message(FATAL_ERROR
                    "Add GNU configure host for $peacock_compiler_id")
            endif()
        elseif(target_system_name STREQUAL "darwin")
            if(peacock_compiler_id STREQUAL "gcc")
                set(peacock_gnu_configure_host "x86_64-apple-darwin")
            elseif(peacock_compiler_id STREQUAL "clang")
                set(peacock_gnu_configure_host "x86_64-apple-darwin")
            else()
                message(FATAL_ERROR "Add GNU configure host")
            endif()
        elseif(target_system_name STREQUAL "windows")
            if(peacock_compiler_id STREQUAL "mingw")
                set(peacock_gnu_configure_host "x86_64-w64-mingw32")
            elseif(peacock_compiler_id STREQUAL "msvc")
                set(peacock_gnu_configure_host "x86_64-w64-windows")
            else()
                message(FATAL_ERROR "Add GNU configure host")
            endif()
        elseif(target_system_name STREQUAL "cygwin")
            message(FATAL_ERROR Add "configure host spec")
        else()
            message(FATAL_ERROR "Add GNU configure host for system/target: "
                "${target_system_name}/${target_architecture}")
        endif()
    endif()

    # TODO build_spec:
    # - i686-pc-cygwin

endif()  # CMAKE_CXX_COMPILER_ID


message(STATUS "peacock: host_system_name     : "
    "${host_system_name} (${CMAKE_HOST_SYSTEM_NAME})")
message(STATUS "peacock: target_system_name   : "
    "${target_system_name} (${CMAKE_SYSTEM_NAME})")
if(peacock_compiler_found)
    message(STATUS "peacock: cross_compiling      : "
        ${peacock_cross_compiling})
    message(STATUS "peacock: target_architecture  : " ${target_architecture})
    message(STATUS "peacock: compiler_id          : " ${peacock_compiler_id})
    message(STATUS "peacock: compiler_version     : " ${peacock_compiler_version})
    message(STATUS "peacock: compiler_main_version: "
        ${peacock_compiler_main_version})
    message(STATUS "peacock: target_platform      : "
        ${peacock_target_platform})
    message(STATUS "peacock: gnu_configure_host   : "
        ${peacock_gnu_configure_host})
endif()
