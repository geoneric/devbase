# Peacock is a project for building external software. It can be used to
# build the Boost libraries on all kinds of platform, for example. A
# PEACOCK_PREFIX CMake variable or environment variable can be set to
# point us to the root of the platform-specific files. By adding the
# current platform string to this prefix, we end up at the root of the
# header files and libraries.
# See also: https://github.com/geoneric/peacock

# If the PEACOCK_PREFIX CMake variable is not set, but an environment
# variable with that name is, then copy it to a CMake variable. This way
# the CMake variable takes precedence.
if((NOT PEACOCK_PREFIX) AND (DEFINED ENV{PEACOCK_PREFIX}))
    set(PEACOCK_PREFIX $ENV{PEACOCK_PREFIX})
endif()

if(PEACOCK_PREFIX)
    set(CMAKE_PREFIX_PATH
        ${PEACOCK_PREFIX}/${peacock_target_platform}
        ${CMAKE_PREFIX_PATH}
    )
    message(STATUS "Probing Peacock builds in: ${PEACOCK_PREFIX}/${peacock_target_platform}")
    set(CMAKE_INCLUDE_DIRECTORIES_BEFORE TRUE)
endif()


# Configure and find packages, configure project. ------------------------------
if(DEVBASE_BOOST_REQUIRED)
    set(Boost_USE_STATIC_LIBS OFF)
    set(Boost_USE_STATIC_RUNTIME OFF)
    add_definitions(
        # Use dynamic libraries.
        -DBOOST_ALL_DYN_LINK
        # Prevent auto-linking.
        -DBOOST_ALL_NO_LIB

        # No deprecated features.
        -DBOOST_FILESYSTEM_NO_DEPRECATED

        # -DBOOST_CHRONO_DONT_PROVIDE_HYBRID_ERROR_HANDLING
        # -DBOOST_CHRONO_HEADER_ONLY
    )
    set(CMAKE_CXX_FLAGS_RELEASE
        # Disable range checks in release builds.
        "${CMAKE_CXX_FLAGS_RELEASE} -DBOOST_DISABLE_ASSERTS"
    )
    list(REMOVE_DUPLICATES DEVBASE_REQUIRED_BOOST_COMPONENTS)
    find_package(Boost REQUIRED
        COMPONENTS ${DEVBASE_REQUIRED_BOOST_COMPONENTS})
    include_directories(
        SYSTEM
        ${Boost_INCLUDE_DIRS}
    )
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${Boost_LIBRARIES}
    )
    message(STATUS "  includes : ${Boost_INCLUDE_DIRS}")
    message(STATUS "  libraries: ${Boost_LIBRARIES}")

    # In older versions of Boost, signal2's scoped_connection was not
    # movable. This has implications when storing these in a collection.
    if(Boost_VERSION VERSION_GREATER "105600")
        set(DEVBASE_BOOST_SCOPED_CONNECTION_IS_MOVABLE TRUE)
    else()
        set(DEVBASE_BOOST_SCOPED_CONNECTION_IS_MOVABLE FALSE)
    endif()

    # In older versions of Boost, lexical cast didn't provide
    # try_lexical_convert.
    if(Boost_VERSION VERSION_GREATER "105500")
        set(DEVBASE_BOOST_LEXICAL_CAST_PROVIDES_TRY_LEXICAL_CONVERT TRUE)
    else()
        set(DEVBASE_BOOST_LEXICAL_CAST_PROVIDES_TRY_LEXICAL_CONVERT FALSE)
    endif()

endif()


if(DEVBASE_CURL_REQUIRED)
    find_package(CURL REQUIRED)
    include_directories(
        SYSTEM
        ${CURL_INCLUDE_DIRS}
    )
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${CURL_LIBRARIES}
    )
endif()


if(DEVBASE_CURSES_REQUIRED)
    # set(CURSES_NEED_NCURSES TRUE)  # Assume we need this one for now.

    find_package(Curses REQUIRED)
    # Check CURSES_HAVE_NCURSES_H -> cursesw.h in .../include
    # Check CURSES_HAVE_NCURSES_NCURSES_H -> curses.h in .../ncursesw
    # Simplify this, use CMAKE_INSTALL_PREFIX to point CMake to /opt/local.
    if(NOT APPLE)
        include_directories(
            SYSTEM
            ${CURSES_INCLUDE_DIRS}  # /ncursesw
        )
    else()
        include_directories(
            SYSTEM
            /opt/local/include
        )
        link_directories(
            /opt/local/lib
        )
    endif()

    if(NOT DEFINED DEVBASE_CURSES_WIDE_CHARACTER_SUPPORT_REQUIRED)
        set(DEVBASE_CURSES_WIDE_CHARACTER_SUPPORT_REQUIRED TRUE)
    endif()

    if(DEVBASE_CURSES_WIDE_CHARACTER_SUPPORT_REQUIRED)
        set(CURSES_LIBRARIES formw menuw ncursesw)
    endif()

    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${CURSES_LIBRARIES}
    )
endif()


if(DEVBASE_DOXYGEN_REQUIRED)
    find_package(Doxygen REQUIRED)
endif()


if(DEVBASE_GDAL_REQUIRED)
    find_package(GDAL REQUIRED)
    include_directories(
        SYSTEM
        ${GDAL_INCLUDE_DIRS}
    )
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${GDAL_LIBRARIES}
    )
    find_program(GDAL_TRANSLATE gdal_translate
        HINTS ${GDAL_INCLUDE_DIR}/../bin
    )
    # TODO This dir isn't correct. GDAL_DIRECTORY is not defined.
    if(WIN32)
        SET(GDAL_DATA ${GDAL_DIRECTORY}/data)
    else()
        SET(GDAL_DATA ${GDAL_DIRECTORY}/share/gdal)
    endif()
endif()


if(DEVBASE_GEOS_REQUIRED)
    find_package(GEOS REQUIRED)
    include_directories(
        SYSTEM
        ${GEOS_INCLUDE_DIR}
    )
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${GEOS_LIBRARY}
    )
endif()


if(DEVBASE_IMAGE_MAGICK_REQUIRED)
    FIND_PACKAGE(ImageMagick REQUIRED
        COMPONENTS convert)
endif()


if(DEVBASE_LIB_XML2_REQUIRED)
    FIND_PACKAGE(LibXml2 REQUIRED)
endif()


if(DEVBASE_LIB_XSLT_REQUIRED)
    FIND_PACKAGE(LibXslt REQUIRED)

    if(DEVBASE_LIB_XSLT_XSLTPROC_REQUIRED)
        if(NOT LIBXSLT_XSLTPROC_EXECUTABLE)
            message(FATAL_ERROR "xsltproc executable not found")
        endif()
    endif()
endif()


if(DEVBASE_OPENGL_REQUIRED)
    find_package(OpenGL REQUIRED)

    include_directories(
        SYSTEM
        ${OPENGL_INCLUDE_DIR}
    )
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${OPENGL_LIBRARIES}
    )
endif()


if(DEVBASE_PCRASTER_RASTER_FORMAT_REQUIRED)
    find_package(PCRasterRasterFormat REQUIRED)
    include_directories(
        ${PCRASTER_RASTER_FORMAT_INCLUDE_DIRS}
    )
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${PCRASTER_RASTER_FORMAT_LIBRARIES}
    )
endif()


if(DEVBASE_PYTHON_INTERP_REQUIRED)
    if(DEFINED DEVBASE_REQUIRED_PYTHON_VERSION)
        set(Python_ADDITIONAL_VERSIONS ${DEVBASE_REQUIRED_PYTHON_VERSION})
    endif()

    find_package(PythonInterp REQUIRED)
endif()


if(DEVBASE_PYTHON_LIBS_REQUIRED)
    if(DEFINED DEVBASE_REQUIRED_PYTHON_VERSION)
        set(Python_ADDITIONAL_VERSIONS ${DEVBASE_REQUIRED_PYTHON_VERSION})
    endif()

    find_package(PythonLibs REQUIRED)
    include_directories(
        SYSTEM
        ${PYTHON_INCLUDE_DIRS}
    )
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${PYTHON_LIBRARIES}
    )
endif()


if(DEVBASE_QT_REQUIRED)
    if(NOT DEFINED DEVBASE_REQUIRED_QT_VERSION)
        set(DEVBASE_REQUIRED_QT_VERSION "5")
    endif()

    if(DEVBASE_REQUIRED_QT_VERSION VERSION_EQUAL "4")
        find_package(Qt4 REQUIRED)
        include(${QT_USE_FILE})

        # Explicitly configure Qt's include directory. This is also done in
        # ${QT_USE_FILE} above, but we want to shove the SYSTEM option in.
        include_directories(
            SYSTEM
            ${QT_INCLUDE_DIR}
        )
    else()
        # http://doc.qt.io/qt-5/cmake-manual.html

        ### # Find includes in corresponding build directories
        ### set(CMAKE_INCLUDE_CURRENT_DIR ON)

        ### # Instruct CMake to run moc automatically when needed.
        ### set(CMAKE_AUTOMOC ON)

        find_package(Qt5Widgets REQUIRED)
    endif()
endif()


if(DEVBASE_QWT_REQUIRED)
    find_package(Qwt REQUIRED)

    include_directories(
        SYSTEM
        ${QWT_INCLUDE_DIR}
    )
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${QWT_LIBRARY}
    )
    message(STATUS "Found Qwt: ${Boost_INCLUDE_DIRS}")
    message(STATUS "  includes : ${QWT_INCLUDE_DIRS}")
    message(STATUS "  libraries: ${QWT_LIBRARIES}")
endif()


if(DEVBASE_SQLITE_REQUIRED)
    find_package(SQLite3 REQUIRED)
endif()


if(DEVBASE_XERCES_REQUIRED)
    find_package(XercesC REQUIRED)
    include_directories(
        SYSTEM
        ${XercesC_INCLUDE_DIRS}
    )
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${XercesC_LIBRARIES}
    )
endif()


if(DEVBASE_XSD_REQUIRED)
    find_package(XSD REQUIRED)
    include_directories(
        SYSTEM
        ${XSD_INCLUDE_DIRS}
    )
    # list(APPEND DEVBASE_EXTERNAL_SOURCES ${XSD_INCLUDE_DIRS})
    # list(APPEND DEVBASE_EXTERNAL_SOURCES_FILE_PATTERNS *.ixx)
    # list(APPEND DEVBASE_EXTERNAL_SOURCES_FILE_PATTERNS *.txx)
    message(STATUS "Found XSD:")
    message(STATUS "  includes  : ${XSD_INCLUDE_DIRS}")
    message(STATUS "  executable: ${XSD_EXECUTABLE}")
endif()
