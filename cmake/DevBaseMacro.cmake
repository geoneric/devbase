include(CheckCXXSourceRuns)
include(CMakeParseArguments)


macro(add_parser_generation_command
        BASENAME)
    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/${BASENAME}.map.in
        ${CMAKE_CURRENT_BINARY_DIR}/${BASENAME}.map
    )

    add_custom_command(
        OUTPUT
            ${CMAKE_CURRENT_BINARY_DIR}/${BASENAME}-pskel.hxx
            ${CMAKE_CURRENT_BINARY_DIR}/${BASENAME}-pskel.cxx
        COMMAND
            ${XSD_EXECUTABLE} cxx-parser
                --std c++11
                --xml-parser expat
                --type-map ${CMAKE_CURRENT_BINARY_DIR}/${BASENAME}.map
                ${ARGN}
                ${CMAKE_CURRENT_SOURCE_DIR}/${BASENAME}.xsd
        DEPENDS
            ${CMAKE_CURRENT_BINARY_DIR}/${BASENAME}.map
            ${CMAKE_CURRENT_SOURCE_DIR}/${BASENAME}.xsd
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )
endmacro()


macro(add_tree_generation_command
        BASENAME)
    add_custom_command(
        OUTPUT
            ${CMAKE_CURRENT_BINARY_DIR}/${BASENAME}.hxx
            ${CMAKE_CURRENT_BINARY_DIR}/${BASENAME}.cxx
        COMMAND
            ${XSD_EXECUTABLE} cxx-tree
                --std c++11
                --generate-doxygen
                --generate-serialization
                ${ARGN}
                ${CMAKE_CURRENT_SOURCE_DIR}/${BASENAME}.xsd
        DEPENDS
            ${CMAKE_CURRENT_SOURCE_DIR}/${BASENAME}.xsd
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )
endmacro()


# Create a static library and an object library.
# BASENAME: Name of static library to create. The object library will be
#           named ${BASENAME}_objects.
# SOURCES : Sources that are part of the libraries. Any argument that comes
#           after the BASENAME is treated as a source.
macro(add_library_and_object_library
        BASENAME)
    set(SOURCES ${ARGN})
    add_library(${BASENAME}
        ${SOURCES}
    )
    add_library(${BASENAME}_objects OBJECT
        ${SOURCES}
    )
endmacro()


# Verify that headers are self-sufficient: they include the headers they need.
# OFFSET_PATHNAME : Pathname to root of headers.
# INCLUDES        : Pathnames where included headers can be found.
# LIBRARIES       : Libraries to link.
# FLAGS           : Compiler flags.
# HEADER_PATHNAMES: Pathnames to headers to verify.
# 
# Cache veriables will be set that are named after the headers:
# <header_name>_IS_STANDALONE
macro(verify_headers_are_self_sufficient)
    set(OPTIONS "")
    set(ONE_VALUE_ARGUMENTS OFFSET_PATHNAME FLAGS)
    set(MULTI_VALUE_ARGUMENTS INCLUDES LIBRARIES HEADER_PATHNAMES)
    cmake_parse_arguments(VERIFY_HEADERS "${OPTIONS}" "${ONE_VALUE_ARGUMENTS}"
        "${MULTI_VALUE_ARGUMENTS}" ${ARGN})

    if(VERIFY_HEADERS_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "Macro called with unrecognized arguments: "
            "${VERIFY_HEADERS_UNPARSED_ARGUMENTS}"
        )
    endif()

    set(CMAKE_REQUIRED_FLAGS "${VERIFY_HEADERS_FLAGS}")
    # set(CMAKE_REQUIRED_DEFINITIONS xxx)
    set(CMAKE_REQUIRED_INCLUDES ${VERIFY_HEADERS_INCLUDES})
    set(CMAKE_REQUIRED_LIBRARIES ${VERIFY_HEADERS_LIBRARIES})

    foreach(HEADER_PATHNAME ${VERIFY_HEADERS_HEADER_PATHNAMES})
        string(REPLACE ${VERIFY_HEADERS_OFFSET_PATHNAME} "" HEADER_NAME
            ${HEADER_PATHNAME})

        # Create variable name that contains the name of the header being
        # checked and is a valid macro name. It is passed to the compiler:
        # -D${VARIABLE_NAME}. That meanѕ that some characters cannot be in
        # the name.
        set(VARIABLE_NAME ${HEADER_NAME})
        string(REPLACE /  _ VARIABLE_NAME ${VARIABLE_NAME})
        string(REPLACE \\ _ VARIABLE_NAME ${VARIABLE_NAME})
        string(REPLACE .  _ VARIABLE_NAME ${VARIABLE_NAME})

        # - Include the header twice to see whether the '#pragma once' is in
        #   place.
        # - Compile a dummy main to see whether the header includes everything
        #   it uses.
        check_cxx_source_compiles("
            #include \"${HEADER_NAME}\"
            #include \"${HEADER_NAME}\"
            int main(int /* argc */, char** /* argv */) {
              return 0;
            }"
            ${VARIABLE_NAME})

        if(NOT ${VARIABLE_NAME})
            message(FATAL_ERROR
                "Header ${HEADER_NAME} is not self-sufficient. "
                "Inspect CMakeFiles/{CMakeError.log,CMakeOutput.log}."
            )
        endif()
    endforeach()
endmacro()


# TODO Can we somehow configure the extension to end up in bin/python instead
# TODO of bin? Currently we cannot have a dll and a python extension
# TODO both named bla. On Windows the import lib of the python extension will
# TODO conflict with the import lib of the dll.
macro(configure_python_extension
        EXTENTION_TARGET
        EXTENSION_NAME)
    set_target_properties(${EXTENTION_TARGET}
        PROPERTIES
            OUTPUT_NAME "${EXTENSION_NAME}"
    )

    # Configure suffix and prefix, depending on the Python OS conventions.
    set_target_properties(${EXTENTION_TARGET}
        PROPERTIES
            PREFIX ""
    )

    if(WIN32)
        set_target_properties(${EXTENTION_TARGET}
            PROPERTIES
                DEBUG_POSTFIX "_d"
                SUFFIX ".pyd"
        )
    else(WIN32)
        set_target_properties(${EXTENTION_TARGET}
            PROPERTIES
                SUFFIX ".so"
        )
    endif(WIN32)
endmacro()


# Add a test target.
# Also configures the environment to point to the location of shared libs.
# The idea of this is to keep the dev's shell as clean as possible. Use
# ctest command to run unit tests.
# SCOPE: Some prefix. Often the lib name of the lib being tested.
# NAME : Name of test module, without extension.
# LINK_LIBRARIES: Libraries to link against.
# DEPENDENCIES: Targets this test target depends on.
macro(add_unit_test)
    set(OPTIONS "")
    set(ONE_VALUE_ARGUMENTS SCOPE NAME)
    set(MULTI_VALUE_ARGUMENTS
        SUPPORT_NAMES
        INCLUDE_DIRS
        OBJECT_LIBRARIES
        LINK_LIBRARIES
        DEPENDENCIES
    )

    cmake_parse_arguments(ADD_UNIT_TEST "${OPTIONS}" "${ONE_VALUE_ARGUMENTS}"
        "${MULTI_VALUE_ARGUMENTS}" ${ARGN})

    if(ADD_UNIT_TEST_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "Macro called with unrecognized arguments: "
            "${ADD_UNIT_TEST_UNPARSED_ARGUMENTS}"
        )
    endif()

    set(TEST_MODULE_NAME ${ADD_UNIT_TEST_NAME})
    set(TEST_EXE_NAME ${ADD_UNIT_TEST_SCOPE}_${TEST_MODULE_NAME})
    string(REPLACE "/" "_" TEST_EXE_NAME ${TEST_EXE_NAME})

    add_executable(${TEST_EXE_NAME} ${TEST_MODULE_NAME}
        ${ADD_UNIT_TEST_SUPPORT_NAMES}
        ${ADD_UNIT_TEST_OBJECT_LIBRARIES})
    target_compile_definitions(${TEST_EXE_NAME}
        PRIVATE
            BOOST_ALL_DYN_LINK
    )
    target_include_directories(${TEST_EXE_NAME}
        PRIVATE
            ${ADD_UNIT_TEST_INCLUDE_DIRS}
            ${Boost_INCLUDE_DIRS})
    target_link_libraries(${TEST_EXE_NAME}
        PRIVATE
            ${ADD_UNIT_TEST_LINK_LIBRARIES}
            Boost::unit_test_framework)

    add_test(NAME ${TEST_EXE_NAME}
        # catch_system_errors: Prevent UTF to detect system errors. This
        #     messes things up when doing system calls to Python unit tests.
        #     See also: http://lists.boost.org/boost-users/2009/12/55048.php
        COMMAND ${TEST_EXE_NAME} --catch_system_errors=no)

    if(ADD_UNIT_TEST_DEPENDENCIES)
        ADD_DEPENDENCIES(${TEST_EXE_NAME} ${ADD_UNIT_TEST_DEPENDENCIES})
    endif()

    # Maybe add ${EXECUTABLE_OUTPUT_PATH} in the future. If needed.
    set(PATH_LIST $ENV{PATH})
    list(INSERT PATH_LIST 0 ${Boost_LIBRARY_DIRS})
    set(PATH_STRING "${PATH_LIST}")

    if(${host_system_name} STREQUAL "windows")
        string(REPLACE "\\" "/" PATH_STRING "${PATH_STRING}")
        string(REPLACE ";" "\\;" PATH_STRING "${PATH_STRING}")
    else()
        string(REPLACE ";" ":" PATH_STRING "${PATH_STRING}")
    endif()

    set_property(TEST ${TEST_EXE_NAME}
        PROPERTY ENVIRONMENT "PATH=${PATH_STRING}")
endmacro()


function(add_unit_tests)
    set(OPTIONS "")
    set(ONE_VALUE_ARGUMENTS SCOPE)
    set(MULTI_VALUE_ARGUMENTS
        NAMES
        SUPPORT_NAMES
        INCLUDE_DIRS
        OBJECT_LIBRARIES
        LINK_LIBRARIES
        DEPENDENCIES
    )

    cmake_parse_arguments(ADD_UNIT_TESTS "${OPTIONS}" "${ONE_VALUE_ARGUMENTS}"
        "${MULTI_VALUE_ARGUMENTS}" ${ARGN})

    if(ADD_UNIT_TESTS_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "Macro called with unrecognized arguments: "
            "${ADD_UNIT_TESTS_UNPARSED_ARGUMENTS}"
        )
    endif()

    foreach(NAME ${ADD_UNIT_TESTS_NAMES})
        add_unit_test(
            SCOPE ${ADD_UNIT_TESTS_SCOPE}
            NAME ${NAME}
            SUPPORT_NAMES ${ADD_UNIT_TESTS_SUPPORT_NAMES}
            INCLUDE_DIRS ${ADD_UNIT_TESTS_INCLUDE_DIRS}
            OBJECT_LIBRARIES ${ADD_UNIT_TESTS_OBJECT_LIBRARIES}
            LINK_LIBRARIES ${ADD_UNIT_TESTS_LINK_LIBRARIES})
        set(target_name ${ADD_UNIT_TESTS_SCOPE}_${NAME})
        if(ADD_UNIT_TESTS_DEPENDENCIES)
            add_dependencies(${target_name} ${ADD_UNIT_TESTS_DEPENDENCIES})
        endif()
    endforeach()
endfunction()


# Tests can be added conditionally. When the build is configured, the
# DEVBASE_BUILD_TEST variable can be set to TRUE or FALSE. Depending on
# its setting tests are build or not.
# DIRECTORY_NAME: Name of subdirectory containing the target.
function(add_test_conditionally
        DIRECTORY_NAME)
    if(DEVBASE_BUILD_TEST)
        add_subdirectory(${DIRECTORY_NAME})
    endif()
endfunction()


# Copy Python test modules from current source directory to current binary
# directory. For each module a custom command is created so editing a test
# module in the source directory will trigger a copy to the binary directory.
# Also, a custom target is defined that depends on all copied test modules.
# If you let another target depend on this custom target, then all copied
# test modules will always be up to date before building the other target.
# TARGET: Name of custom target to add.
macro(copy_python_unit_test_modules)
    set(OPTIONS RECURSE)
    set(ONE_VALUE_ARGUMENTS TARGET)
    set(MULTI_VALUE_ARGUMENTS "")

    cmake_parse_arguments(COPY_MODULES "${OPTIONS}" "${ONE_VALUE_ARGUMENTS}"
        "${MULTI_VALUE_ARGUMENTS}" ${ARGN})

    if(COPY_MODULES_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "Macro called with unrecognized arguments: "
            "${COPY_MODULES_UNPARSED_ARGUMENTS}"
        )
    endif()

    if(COPY_MODULES_RECURSE)
        file(GLOB_RECURSE PYTHON_UNIT_TEST_MODULES RELATIVE
            ${CMAKE_CURRENT_SOURCE_DIR} "*.py")
    else()
        file(GLOB PYTHON_UNIT_TEST_MODULES RELATIVE
            ${CMAKE_CURRENT_SOURCE_DIR} "*.py")
    endif()

    foreach(MODULE ${PYTHON_UNIT_TEST_MODULES})
        set(PYTHON_UNIT_TEST_MODULE ${CMAKE_CURRENT_SOURCE_DIR}/${MODULE})
        set(COPIED_PYTHON_UNIT_TEST_MODULE
            ${CMAKE_CURRENT_BINARY_DIR}/${MODULE})
        add_custom_command(
            OUTPUT ${COPIED_PYTHON_UNIT_TEST_MODULE}
            DEPENDS ${PYTHON_UNIT_TEST_MODULE}
            COMMAND ${CMAKE_COMMAND} -E copy ${PYTHON_UNIT_TEST_MODULE}
                ${COPIED_PYTHON_UNIT_TEST_MODULE}
        )
        list(APPEND COPIED_PYTHON_UNIT_TEST_MODULES
            ${COPIED_PYTHON_UNIT_TEST_MODULE})
    endforeach()

    add_custom_target(${COPY_MODULES_TARGET}
        DEPENDS ${COPIED_PYTHON_UNIT_TEST_MODULES})
endmacro()


macro(copy_python_modules)
    set(OPTIONS "")
    set(ONE_VALUE_ARGUMENTS TARGET TARGET_DIRECTORY)
    set(MULTI_VALUE_ARGUMENTS "")

    cmake_parse_arguments(COPY_MODULES "${OPTIONS}" "${ONE_VALUE_ARGUMENTS}"
        "${MULTI_VALUE_ARGUMENTS}" ${ARGN})

    if(COPY_MODULES_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "Macro called with unrecognized arguments: "
            "${COPY_MODULES_UNPARSED_ARGUMENTS}"
        )
    endif()

    file(GLOB PYTHON_MODULES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "*.py")

    foreach(MODULE ${PYTHON_MODULES})
        set(PYTHON_MODULE ${CMAKE_CURRENT_SOURCE_DIR}/${MODULE})
        set(COPIED_PYTHON_MODULE ${COPY_MODULES_TARGET_DIRECTORY}/${MODULE})
        add_custom_command(
            OUTPUT ${COPIED_PYTHON_MODULE}
            DEPENDS ${PYTHON_MODULE}
            COMMAND ${CMAKE_COMMAND} -E copy ${PYTHON_MODULE}
                ${COPIED_PYTHON_MODULE}
        )
        list(APPEND COPIED_PYTHON_MODULES ${COPIED_PYTHON_MODULE})
    endforeach()

    add_custom_target(${COPY_MODULES_TARGET}
        DEPENDS ${COPIED_PYTHON_MODULES})
endmacro()


macro(force_out_of_tree_build)
    string(COMPARE EQUAL "${CMAKE_SOURCE_DIR}" "${CMAKE_BINARY_DIR}"
        in_source_build)
    if(in_source_build)
        message(FATAL_ERROR "Project must be built out-of-source")
    endif()
endmacro()


# Copy a test data file.
function(copy_test_file)
    set(OPTIONS "")
    set(ONE_VALUE_ARGUMENTS
        SOURCE_FILE_PATHNAME
        DESTINATION_FILENAME
        PERMISSIONS
        DESTINATION_FILE_PATHNAMES_LIST)
    set(MULTI_VALUE_ARGUMENTS "")

    cmake_parse_arguments(COPY_TEST_FILE "${OPTIONS}" "${ONE_VALUE_ARGUMENTS}"
        "${MULTI_VALUE_ARGUMENTS}" ${ARGN})

    if(COPY_TEST_FILE_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "Macro called with unrecognized arguments: "
            "${COPY_TEST_FILE_UNPARSED_ARGUMENTS}"
        )
    endif()

    set(source_file_pathname ${COPY_TEST_FILE_SOURCE_FILE_PATHNAME})
    set(destination_filename ${COPY_TEST_FILE_DESTINATION_FILENAME})
    set(destination_file_pathname
        ${CMAKE_CURRENT_BINARY_DIR}/${destination_filename})
    set(destination_file_pathnames_list
        ${COPY_TEST_FILE_DESTINATION_FILE_PATHNAMES_LIST})
    set(permissions ${COPY_TEST_FILE_PERMISSIONS})

    if(permissions)
        if(${permissions} STREQUAL WRITE_ONLY)
            add_custom_command(
                OUTPUT ${destination_file_pathname}
                WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                COMMAND ${CMAKE_COMMAND} -E remove -f ${destination_filename}
                COMMAND ${CMAKE_COMMAND} -E copy ${source_file_pathname}
                    ${destination_filename}
                COMMAND chmod 222 ${destination_filename}
                DEPENDS ${source_file_pathname}
            )
        endif()
    else()
        add_custom_command(
            OUTPUT ${destination_file_pathname}
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
            COMMAND ${CMAKE_COMMAND} -E remove -f ${destination_filename}
            COMMAND ${CMAKE_COMMAND} -E copy ${source_file_pathname}
                ${destination_filename}
            DEPENDS ${source_file_pathname}
        )
    endif()

    set(${destination_file_pathnames_list} ${${destination_file_pathnames_list}}
        ${destination_file_pathname} PARENT_SCOPE)
endfunction()


function(add_object_library)
    set(OPTIONS "")
    set(ONE_VALUE_ARGUMENTS
        TARGET  # Object library name.
        LIBRARY)  # Library name the object library is part of.
    set(MULTI_VALUE_ARGUMENTS SOURCES)  # Source files.

    cmake_parse_arguments(ADD_OBJECT_LIBRARY "${OPTIONS}"
        "${ONE_VALUE_ARGUMENTS}" "${MULTI_VALUE_ARGUMENTS}" ${ARGN})

    if(ADD_OBJECT_LIBRARY_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "Macro called with unrecognized arguments: "
            "${ADD_OBJECT_LIBRARY_UNPARSED_ARGUMENTS}"
        )
    endif()

    set(target ${ADD_OBJECT_LIBRARY_TARGET})
    set(sources ${ADD_OBJECT_LIBRARY_SOURCES})
    set(library ${ADD_OBJECT_LIBRARY_LIBRARY})

    # Object library.
    add_library(${target} OBJECT ${sources})

    # Name of variable containing names of object libraries.
    string(TOUPPER ${library} library_variable)
    set(library_variable ${library_variable}_OBJECT_LIBRARIES)

    # Append this object library.
    get_property(${library_variable} GLOBAL PROPERTY ${library_variable})
    set_property(GLOBAL PROPERTY
        ${library_variable}
        ${${library_variable}} $<TARGET_OBJECTS:${target}>
    )
endfunction()
