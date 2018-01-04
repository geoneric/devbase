import os.path
import sys


def filesystem_is_case_sensitive():
    return sys.platform != "win32"


def path_name_components(
        path_name):
    components = []
    while True:
        path_name, base_name = os.path.split(path_name)
        if base_name != "":
            components.append(base_name)
        else:
            if path_name != "":
                components.append(path_name)

            break
    components.reverse()
    return components


def path_names_are_equal(
        path_name1,
        path_name2):
    if not filesystem_is_case_sensitive():
        return path_name1.lower() == path_name2.lower()
    else:
        return path_name1 == path_name2


def commonprefix(
        path_names):
    """
    Return the longest path prefix that is a prefix of all paths names passed
    in.

    In case of a case-insensitive filesystem, the casing of the path names is
    synchronized first.
    """
    if not filesystem_is_case_sensitive():
        return os.path.commonprefix([path_name.lower() for path_name in
            path_names])
    else:
        return os.path.commonprefix(path_names)
