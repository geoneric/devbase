#!/usr/bin/env python
"""Fixup

Usage:
  fixup.py PROJECT_PREFIX EXTERNAL_PREFIX
  fixup.py -h | --help
  fixup.py --version

Options:
  -h --help        Show this screen.
  PROJECT_PREFIX   Path name to install prefix of project to fixup.
  EXTERNAL_PREFIX  Path name to prefix of external software. This should be
                   the root of where 3rd party shared libraries can be found.
"""
import os
import shutil
import sys
import docopt
import devbase


class FileInfo(object):

    def __init__(self,
            directory_name,
            base_name):
        self.directory_name = directory_name
        self.base_name = base_name
        self.absolute_file_name = os.path.join(self.directory_name,
            self.base_name)

    def is_dll_client(self):
        return devbase.file_is_dll_client(self.absolute_file_name)

    def __repr__(self):
        return "FileInfo(\"{}\", \"{}\")".format(self.directory_name,
            self.base_name)


def find_project_dll_clients(
        project_prefix):
    """
    Find all dll clients rooted at project_prefix and return their FileInfo
    instances.
    """
    file_infos = []
    for directory_name, _, file_names in os.walk(project_prefix):
        for file_name in file_names:
            file_info = FileInfo(directory_name, file_name)
            if file_info.is_dll_client():
                assert not os.path.islink(file_info.absolute_file_name)
                assert devbase.file_is_binary(
                    file_info.absolute_file_name), file_info.absolute_file_name
                if sys.platform == "win32":
                    assert devbase.file_is_executable(
                        file_info.absolute_file_name), \
                            file_info.absolute_file_name
                file_infos.append(FileInfo(directory_name, file_name))

    return file_infos


def find_external_dlls(
        project_prefix,
        external_prefix,
        project_dll_clients):
    shared_library_names, missing_shared_library_names = \
        devbase.shared_library_dependencies([dll_client.absolute_file_name for
            dll_client in project_dll_clients])

    # Only select the dlls from the external software prefix. Skip those that
    # are already in the project prefix.
    shared_library_names = [dll_file_name for dll_file_name in \
        shared_library_names if
            (not devbase.path_names_are_equal(
                devbase.commonprefix([dll_file_name, external_prefix]),
                project_prefix)) and
            (devbase.path_names_are_equal(
                devbase.commonprefix([dll_file_name, external_prefix]),
                external_prefix))
    ]

    # See if the missing shared library names can be found in external_prefix's
    # lib directory.
    missing_shared_library_names = [os.path.join(external_prefix, "lib", name) \
        for name in missing_shared_library_names]
    really_missing_shared_library_names = [name for name in
        missing_shared_library_names if not os.path.exists(name)]

    if really_missing_shared_library_names:
        raise RuntimeError(
            "Some dependencies of {} could not be found: {}".format(
                project_dll_clients, ", ".join(
                    really_missing_shared_library_names)))

    shared_library_names += missing_shared_library_names
    return shared_library_names


def copy_dlls_to_project(
        external_dlls,
        project_prefix):
    directory_name = os.path.join(project_prefix, "lib")
    copied_dlls = []
    for external_dll_filename in external_dlls:
        file_info = FileInfo(directory_name, os.path.basename(
            external_dll_filename))
        # Folow symlink and write to origin name.
        shutil.copy2(os.path.realpath(external_dll_filename),
            file_info.absolute_file_name)
        assert not os.path.islink(file_info.absolute_file_name)
        copied_dlls.append(file_info)
    return copied_dlls


def fixup_dll_clients(
        project_dll_clients,
        project_prefix):
    for dll_client in project_dll_clients:
        devbase.fixup_dll_client(dll_client.absolute_file_name, project_prefix)


def fixup(
        project_prefix,
        external_prefix):
    if not os.path.isdir(project_prefix):
        raise ValueError("Project prefix {} does not exist".format(
            project_prefix))
    if not os.path.isdir(external_prefix):
        raise ValueError("External prefix {} does not exist".format(
            external_prefix))
    project_dll_clients = find_project_dll_clients(project_prefix)
    external_dlls = find_external_dlls(
        project_prefix, external_prefix, project_dll_clients)
    copied_dlls = copy_dlls_to_project(external_dlls, project_prefix)
    assert len(external_dlls) == len(copied_dlls)
    dll_clients = project_dll_clients + copied_dlls
    assert len(dll_clients) == len(project_dll_clients) + len(copied_dlls)
    fixup_dll_clients(dll_clients, project_prefix)

    # Below, we search for dependencies on external dlls a second time. The
    # result must be empty, otherwise we didn't copy all external dlls to
    # the project's prefix.

    for dll_client in dll_clients:
        external_dlls = find_external_dlls(project_prefix, external_prefix,
            [dll_client])
        if external_dlls:
            raise RuntimeError(
                "Fixup of {} failed for these external dlls: {}".format(
                    dll_client.absolute_file_name, external_dlls))

    return 0


if __name__ == "__main__":
    arguments = docopt.docopt(__doc__)
    project_prefix = os.path.normcase(
        os.path.abspath(arguments["PROJECT_PREFIX"]))
    external_prefix = os.path.normcase(
        os.path.abspath(arguments["EXTERNAL_PREFIX"]))
    sys.exit(fixup(project_prefix, external_prefix))
