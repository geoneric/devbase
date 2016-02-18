find_path(DOCOPT_INCLUDE_DIR
    NAMES
        docopt/docopt.h
)
set(DOCOPT_INCLUDE_DIRS
    ${DOCOPT_INCLUDE_DIR}
)


find_library(DOCOPT_LIBRARY
    NAMES
        docopt
)
set(DOCOPT_LIBRARIES
    ${DOCOPT_LIBRARY}
)


include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Docopt
    REQUIRED_VARS
        DOCOPT_LIBRARY
        DOCOPT_INCLUDE_DIR
)


mark_as_advanced (
    DOCOPT_INCLUDE_DIR
    DOCOPT_INCLUDE_DIRS
    DOCOPT_LIBRARY
    DOCOPT_LIBRARIES
)
