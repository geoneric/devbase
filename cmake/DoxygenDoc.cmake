set(DOXYGEN_TEMPLATE "
    ALWAYS_DETAILED_SEC     = YES
    BUILTIN_STL_SUPPORT     = YES
    CLASS_DIAGRAMS          = YES
    ENABLE_PREPROCESSING    = YES
    EXCLUDE_PATTERNS        = *Test.h *Test.cc *_test.cc
    EXPAND_ONLY_PREDEF      = NO
    EXTRACT_ALL             = YES
    EXTRACT_PRIVATE         = NO
    EXTRACT_STATIC          = NO
    FILE_PATTERNS           = *.h *.hpp *.hxx *.c *.cc *.cpp *.cxx *.dox *.md ${FERN_EXTERNAL_SOURCES_FILE_PATTERNS}
    FULL_PATH_NAMES         = YES
    GENERATE_LATEX          = NO
    GENERATE_TODOLIST       = ${FERN_DOXYGEN_GENERATE_TODOLIST}
    HAVE_DOT                = YES
    INCLUDE_GRAPH           = YES
    INHERIT_DOCS            = YES
    INLINE_INFO             = YES
    INLINE_INHERITED_MEMB   = YES
    MATHJAX_EXTENSIONS      = TeX/AMSmath TeX/AMSsymbols
    QUIET                   = YES
    RECURSIVE               = YES
    SEARCH_INCLUDES         = YES
    SHOW_FILES              = YES
    SHOW_USED_FILES         = NO
    SHOW_GROUPED_MEMB_INC   = YES
    SORT_MEMBER_DOCS        = NO
    SOURCE_BROWSER          = NO
    STRIP_FROM_INC_PATH     = ${CMAKE_CURRENT_SOURCE_DIR}
    STRIP_FROM_PATH         = ${CMAKE_CURRENT_SOURCE_DIR}
    TEMPLATE_RELATIONS      = YES
    USE_MATHJAX             = YES
    VERBATIM_HEADERS        = NO
    WARN_IF_DOC_ERROR       = YES
    WARN_IF_UNDOCUMENTED    = NO  # Because EXTRACT_ALL is turned on.
    WARNINGS                = YES
    WARN_NO_PARAMDOC        = YES
")

configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/Doxyfile.in
    ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile
)

add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/html/index.html
    COMMAND ${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile
)

add_custom_target(cpp_doc # ALL
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/html/index.html
)
