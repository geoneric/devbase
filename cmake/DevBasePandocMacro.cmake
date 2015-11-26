function(convert_markdown_to_html)
    set(OPTIONS GITHUB_FLAVORED)
    set(ONE_VALUE_ARGUMENTS TARGET)
    set(MULTI_VALUE_ARGUMENTS SOURCES)  # Markdown source files.

    cmake_parse_arguments(CONVERT_MARKDOWN "${OPTIONS}"
        "${ONE_VALUE_ARGUMENTS}" "${MULTI_VALUE_ARGUMENTS}" ${ARGN})

    if(CONVERT_MARKDOWN_UNPARSED_ARGUMENTS)
        message(FATAL_ERROR
            "Macro called with unrecognized arguments: "
            "${CONVERT_MARKDOWN_UNPARSED_ARGUMENTS}"
        )
    endif()

    set(target ${CONVERT_MARKDOWN_TARGET})
    set(sources ${CONVERT_MARKDOWN_SOURCES})

    set(source_format "markdown")
    if(CONVERT_MARKDOWN_GITHUB_FLAVORED)
        set(source_format "${source_format}_github")
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
            ${CMAKE_CURRENT_BINARY_DIR}/${source_name_we}.html)

        add_custom_command(
            OUTPUT ${destination_pathname}
            COMMAND ${PANDOC_EXECUTABLE}
                --standalone
                --from ${source_format}
                --to html5
                --output ${destination_pathname}
                ${source_pathname}
            DEPENDS ${source_pathname}
        )
        list(APPEND destination_pathnames ${destination_pathname})
    endforeach()

    add_custom_target(${CONVERT_MARKDOWN_TARGET}
        DEPENDS ${destination_pathnames})
endfunction()
