# This module defines the following CMake variables:
#  PANDOC_FOUND
#  PANDOC_EXECUTABLE

find_program(PANDOC_EXECUTABLE pandoc)


include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Pandoc
    REQUIRED_VARS
        PANDOC_EXECUTABLE
)

mark_as_advanced(
    PANDOC_EXECUTABLE
)
