# This module defines the following CMake variables:
#  LINKCHECKER_FOUND
#  LINKCHECKER_EXECUTABLE

find_program(LINKCHECKER_EXECUTABLE linkchecker)


include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Linkchecker
    REQUIRED_VARS
        LINKCHECKER_EXECUTABLE
)

mark_as_advanced(
    LINKCHECKER_EXECUTABLE
)
