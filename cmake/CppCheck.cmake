find_program(CPPCHECK_EXECUTABLE cppcheck)

# Gather all include directories.
get_property(include_directories_ DIRECTORY PROPERTY INCLUDE_DIRECTORIES)
set(include_dir_argument -I${PROJECT_SOURCE_DIR}/source
    -I${PROJECT_BINARY_DIR}/source)
foreach(include_directory ${include_directories_})
    set(include_dir_argument -I${include_directory} ${include_dir_argument})
endforeach()

if(CPPCHECK_EXECUTABLE)
    add_custom_command(
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/cppcheck.txt
        # --platform=unix64
        COMMAND ${CPPCHECK_EXECUTABLE} --quiet --enable=all --force
            --language=c++ --std=c++11 ${include_dir_argument}
            ${PROJECT_SOURCE_DIR}/source/fern 2>
                ${CMAKE_CURRENT_BINARY_DIR}/cppcheck.txt)

    add_custom_target(cppcheck
        DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/cppcheck.txt)
endif()
