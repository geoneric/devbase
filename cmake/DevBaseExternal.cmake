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


if(DEVBASE_CURSES_REQUIRED)
    set(CURSES_NEED_NCURSES TRUE)  # Assume we need this one for now.
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
    set(CURSES_LIBRARIES formw menuw ncursesw)
    list(APPEND DEVBASE_EXTERNAL_LIBRARIES
        ${CURSES_LIBRARIES}
    )
    # add_definitions(
    #         -D_X_OPEN_SOURCE_EXTENDED
    #     )
    #     set(CMAKE_CXX_FLAGS_RELEASE
    #         "${CMAKE_CXX_FLAGS_RELEASE} -D_X_OPEN_SOURCE_EXTENDED"
    #     )
endif()


if(DEVBASE_DOXYGEN_REQUIRED)
    find_package(Doxygen REQUIRED)
endif()


if(DEVBASE_QT_REQUIRED)
    # http://doc.qt.io/qt-5/cmake-manual.html

    ### # Find includes in corresponding build directories
    ### set(CMAKE_INCLUDE_CURRENT_DIR ON)

    ### # Instruct CMake to run moc automatically when needed.
    ### set(CMAKE_AUTOMOC ON)

    find_package(Qt5Widgets REQUIRED)
endif()


if(DEVBASE_SQLITE_REQUIRED)
    find_package(SQLite3 REQUIRED)
endif()
