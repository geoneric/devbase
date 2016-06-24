# This module defines the following CMake variables:
#  PYBIND11_FOUND
#  PYBIND11_INCLUDE_DIRS

find_path(PYBIND11_INCLUDE_DIRS
    NAMES pybind11/pybind11.h
)


include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Pybind11
    REQUIRED_VARS
        PYBIND11_INCLUDE_DIRS
)


mark_as_advanced(
    PYBIND11_INCLUDE_DIRS
)
