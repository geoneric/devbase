find_path(LOKI_INCLUDE_DIR loki/Typelist.h)
find_library(LOKI_LIBRARY NAMES loki)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Loki DEFAULT_MSG LOKI_INCLUDE_DIR
    LOKI_LIBRARY)

mark_as_advanced(LOKI_INCLUDE_DIR LOKI_LIBRARY)
