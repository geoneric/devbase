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

IF(DEFINED ENV{FERN_ROOT})
    SET(_FERN_ROOT $ENV{FERN_ROOT})
    SET(_FERN_ROOT_INCLUDE ${_FERN_ROOT}/include)
    SET(_FERN_ROOT_LIB ${_FERN_ROOT}/lib)
ENDIF()


FIND_PATH(FERN_INCLUDE_DIRS
    NAMES fern/core/string.h
    PATHS ${_FERN_ROOT_INCLUDE}
)


FIND_LIBRARY(FERN_ALGORITHM_CORE_LIBRARY
    NAMES fern_algorithm_core
    PATHS ${_FERN_ROOT_LIB}
)
IF(WIN32)
    FIND_LIBRARY(FERN_ALGORITHM_CORE_DEBUG_LIBRARY
        NAMES fern_algorithm_cored
        PATHS ${_FERN_ROOT_LIB}
    )
    SET(FERN_ALGORITHM_CORE_LIBRARY
        optimized ${FERN_ALGORITHM_CORE_LIBRARY}
        debug ${FERN_ALGORITHM_CORE_DEBUG_LIBRARY}
    )
ENDIF()


FIND_LIBRARY(FERN_ALGORITHM_POLICY_LIBRARY
    NAMES fern_algorithm_policy
    PATHS ${_FERN_ROOT_LIB}
)
IF(WIN32)
    FIND_LIBRARY(FERN_ALGORITHM_POLICY_DEBUG_LIBRARY
        NAMES fern_algorithm_policyd
        PATHS ${_FERN_ROOT_LIB}
    )
    SET(FERN_ALGORITHM_POLICY_LIBRARY
        optimized ${FERN_ALGORITHM_POLICY_LIBRARY}
        debug ${FERN_ALGORITHM_POLICY_DEBUG_LIBRARY}
    )
ENDIF()


FIND_LIBRARY(FERN_FEATURE_CORE_LIBRARY
    NAMES fern_feature_core
    PATHS ${_FERN_ROOT_LIB}
)
IF(WIN32)
    FIND_LIBRARY(FERN_FEATURE_CORE_DEBUG_LIBRARY
        NAMES fern_feature_cored
        PATHS ${_FERN_ROOT_LIB}
    )
    SET(FERN_FEATURE_CORE_LIBRARY
        optimized ${FERN_FEATURE_CORE_LIBRARY}
        debug ${FERN_FEATURE_CORE_DEBUG_LIBRARY}
    )
ENDIF()


FIND_LIBRARY(FERN_CORE_LIBRARY
    NAMES fern_core
    PATHS ${_FERN_ROOT_LIB}
)
IF(WIN32)
    FIND_LIBRARY(FERN_CORE_DEBUG_LIBRARY
        NAMES fern_cored
        PATHS ${_FERN_ROOT_LIB}
    )
    SET(FERN_CORE_LIBRARY
        optimized ${FERN_CORE_LIBRARY}
        debug ${FERN_CORE_DEBUG_LIBRARY}
    )
ENDIF()


SET(FERN_LIBRARIES
    ${FERN_ALGORITHM_CORE_LIBRARY}
    ${FERN_ALGORITHM_POLICY_LIBRARY}
    ${FERN_FEATURE_CORE_LIBRARY}
    ${FERN_CORE_LIBRARY}
)


INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(Fern
    REQUIRED_VARS
        FERN_LIBRARIES
        FERN_INCLUDE_DIRS
)


MARK_AS_ADVANCED(
    FERN_LIBRARIES
    FERN_INCLUDE_DIRS
)
