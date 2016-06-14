# Check links in html files.
function(check_for_broken_links)
    set(OPTIONS "")
    set(ONE_VALUE_ARGUMENTS TARGET CONFIGURATION_FILE)
    set(MULTI_VALUE_ARGUMENTS IGNORE_URLS SOURCES)  # Html source files.

    cmake_parse_arguments(CHECK_LINKS "${OPTIONS}"
        "${ONE_VALUE_ARGUMENTS}" "${MULTI_VALUE_ARGUMENTS}" ${ARGN})

    if(CHECK_LINKS_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "Macro called with unrecognized arguments: "
            "${CHECK_LINKS_UNPARSED_ARGUMENTS}"
        )
    endif()

    set(sources ${CHECK_LINKS_SOURCES})

    foreach(url_regex ${CHECK_LINKS_IGNORE_URLS})
        list(APPEND ignore_urls_option "--ignore-url=${url_regex}")
    endforeach()

    if(CHECK_LINKS_CONFIGURATION_FILE)
        set(configuration_file_option
            "--config=${CHECK_LINKS_CONFIGURATION_FILE}")
    endif()

    foreach(source_filename ${sources})
        get_filename_component(source_directory ${source_filename} DIRECTORY)
        get_filename_component(source_name ${source_filename} NAME)
        get_filename_component(source_name_we ${source_name} NAME_WE)

        if(source_directory)
            if(NOT IS_ABSOLUTE ${source_directory})
                set(source_directory
                    ${CMAKE_CURRENT_SOURCE_DIR}/${source_directory})
            endif()
        else()
            set(source_directory ${CMAKE_CURRENT_SOURCE_DIR})
        endif()

        set(source_pathname ${source_directory}/${source_name})
        set(destination_pathname
            ${CMAKE_CURRENT_BINARY_DIR}/${source_name}.lnkchk)

        add_custom_command(
            OUTPUT ${destination_pathname}
            COMMAND ${LINKCHECKER_EXECUTABLE}
                # We are only interested in the links in the current file,
                # not in the links in linked files.
                --recursion-level=1
                --no-status
                ${configuration_file_option}
                ${ignore_urls_option}
                ${source_pathname}
            VERBATIM
            COMMAND ${CMAKE_COMMAND} -E touch ${destination_pathname}
            DEPENDS ${source_pathname}
        )
        list(APPEND destination_pathnames ${destination_pathname})
    endforeach()

    add_custom_target(${CHECK_LINKS_TARGET}
        DEPENDS ${destination_pathnames})
endfunction()
