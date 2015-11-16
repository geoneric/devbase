# Geoneric Fern library is available at
# https://www.geoneric.eu
#
# This module defines the following CMake variables:
#  FERN_FOUND
#  FERN_INCLUDE_DIRS
#  FERN_LIBRARIES
#
# This module uses the folowing environment variables:
#  FERN_ROOT: Directory where the Fern software is installed. It is assumed
#             that the Fern headers and libraries can be found in
#             ${FERN_ROOT}/include and ${FERN_ROOT}/lib, respectively.

if(DEFINED ENV{FERN_ROOT})
    SET(_FERN_ROOT $ENV{FERN_ROOT})
    SET(_FERN_ROOT_INCLUDE ${_FERN_ROOT}/include)
    SET(_FERN_ROOT_LIB ${_FERN_ROOT}/lib)
endif()


find_path(FERN_INCLUDE_DIRS
    NAMES fern/core/string.h
    PATHS ${_FERN_ROOT_INCLUDE}
)


find_library(FERN_ALGORITHM_LIBRARY
    NAMES fern_algorithm
    PATHS ${_FERN_ROOT_LIB}
)
if(WIN32)
    find_library(FERN_ALGORITHM_DEBUG_LIBRARY
        NAMES fern_algorithmd
        PATHS ${_FERN_ROOT_LIB}
    )
    set(FERN_ALGORITHM_LIBRARY
        optimized ${FERN_ALGORITHM_LIBRARY}
        debug ${FERN_ALGORITHM_DEBUG_LIBRARY}
    )
endif()


find_library(FERN_FEATURE_LIBRARY
    NAMES fern_feature
    PATHS ${_FERN_ROOT_LIB}
)
if(WIN32)
    find_library(FERN_FEATURE_DEBUG_LIBRARY
        NAMES fern_featured
        PATHS ${_FERN_ROOT_LIB}
    )
    set(FERN_FEATURE_LIBRARY
        optimized ${FERN_FEATURE_LIBRARY}
        debug ${FERN_FEATURE_DEBUG_LIBRARY}
    )
endif()


find_library(FERN_CORE_LIBRARY
    NAMES fern_core
    PATHS ${_FERN_ROOT_LIB}
)
if(WIN32)
    find_library(FERN_CORE_DEBUG_LIBRARY
        NAMES fern_cored
        PATHS ${_FERN_ROOT_LIB}
    )
    set(FERN_CORE_LIBRARY
        optimized ${FERN_CORE_LIBRARY}
        debug ${FERN_CORE_DEBUG_LIBRARY}
    )
endif()


set(FERN_LIBRARIES
    ${FERN_ALGORITHM_LIBRARY}
    ${FERN_FEATURE_LIBRARY}
    ${FERN_CORE_LIBRARY}
)


include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Fern
    REQUIRED_VARS
        FERN_LIBRARIES
        FERN_INCLUDE_DIRS
)


mark_as_advanced(
    FERN_LIBRARIES
    FERN_INCLUDE_DIRS
)
