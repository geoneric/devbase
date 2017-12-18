"""
Module with filesystem related utilities.
"""
### import filecmp
import os
### import shutil
### import stat
import sys
### import devenv.process
### 
### 
### MSYS_OS_TYPE = "msys"
### 
### CYGWIN_OS_TYPE = "cygwin"
### 
### 
### def os_type():
###     """
###     Return OS type (silly name).
### 
###     Currently only works on Windows. Value returned is either
###     :py:const:`MSYS_OS_TYPE` or :py:const:`CYGWIN_OS_TYPE`.
###     """
###     if os.environ.has_key("MSYSTEM"):
###         result = MSYS_OS_TYPE
###     elif os.environ.has_key("CYGWIN"):
###         result = CYGWIN_OS_TYPE
###     else:
###         assert False, "unknown os type"
###     return result


def file_is_binary(
        path_name):
    """
    .. todo::

       Document.

    """
    # http://stackoverflow.com/questions/898669/how-can-i-detect-if-a-file-is-binary-non-text-in-python
    with open(path_name, "rb") as file_:
        CHUNKSIZE = 1024
        while 1:
            chunk = file_.read(CHUNKSIZE)
            if b"\0" in chunk:  # Found null byte.
                return True
            if len(chunk) < CHUNKSIZE:
                break

    return False


def file_is_executable_default(
        path_name):
    # linux: has the x mode bit set
    # windows: has an extension that is in PATHEXT
    return file_is_binary(path_name) and \
        (not os.path.islink(path_name)) and \
        os.access(path_name, os.X_OK)


def file_is_executable_linux(
        path_name):
    return file_is_executable_default(path_name)


def file_is_executable_darwin(
        path_name):
    return file_is_executable_default(path_name) and \
        not os.path.splitext(path_name)[1] in [".png", ".py", ".idx", ".gif"]


def file_is_executable_win32(
        path_name):
    # On Windows, CMake installs import and static libs as executable files...
    # TODO windows: has an extension that is in PATHEXT
    return os.path.splitext(path_name)[1].lower() in [
        ".com", ".drv", ".exe", ".dll", ".pyd"]


def file_is_executable(
        path_name):
    """
    .. todo::

       Document.

    """
    # File is binary.
    # File is executable.
    # It is not about permissions, it is about link properties.
    file_is_executable_by_platform = {
        "darwin": file_is_executable_darwin,
        "linux2": file_is_executable_linux,
        "win32": file_is_executable_win32
    }
    return file_is_executable_by_platform[sys.platform](path_name)


def file_is_shared_library_linux(
        path_name):
    return (not os.path.islink(path_name)) and path_name.find(".so") != -1


def file_is_shared_library_darwin(
        path_name):
    return (not os.path.islink(path_name)) and (path_name.find(".so") != -1 or
        path_name.find(".dylib") != -1)


def file_is_shared_library_win32(
        path_name):
    return (not os.path.islink(path_name)) and (path_name.find(".dll") != -1 or
        path_name.find(".pyd") != -1)


def file_is_shared_library(
        path_name):
    """
    .. todo::

       Document.

    """
    file_is_shared_library_by_platform = {
        "darwin": file_is_shared_library_darwin,
        "linux2": file_is_shared_library_linux,
        "win32": file_is_shared_library_win32
    }
    return file_is_shared_library_by_platform[sys.platform](path_name)


### def file_is_statically_linked_win32(
###         path_name):
###     assert False
### 
### 
### def file_is_statically_linked_linux(
###         path_name):
###     command = "file {}".format(path_name)
###     return "statically linked" in devenv.process.execute2(command)
### 
### 
### def file_is_statically_linked_darwin(
###         path_name):
###     assert False
### 
### 
### def file_is_statically_linked(
###     path_name):
###     """
###     .. todo::
### 
###        Document.
### 
###     """
###     file_is_statically_linked_by_platform = {
###         "darwin": file_is_statically_linked_darwin,
###         "linux2": file_is_statically_linked_linux,
###         "win32": file_is_statically_linked_win32
###     }
###     return file_is_statically_linked_by_platform[sys.platform](path_name)


def file_is_dynamically_linked_win32(
        path_name):
    return file_is_executable_win32(path_name)


def file_is_dynamically_linked_linux(
        path_name):
    command = "file {}".format(path_name)
    return "dynamically linked" in devenv.process.execute2(command)


def file_is_dynamically_linked_darwin(
        path_name):
    assert False


def file_is_dynamically_linked(
    path_name):
    """
    .. todo::

       Document.

    """
    file_is_dynamically_linked_by_platform = {
        "darwin": file_is_dynamically_linked_darwin,
        "linux2": file_is_dynamically_linked_linux,
        "win32": file_is_dynamically_linked_win32
    }
    return file_is_dynamically_linked_by_platform[sys.platform](path_name)


def file_is_dll_client_unix(
        path_name):
    return file_is_dynamically_linked(path_name)


def file_is_dll_client_win32(
        path_name):
    return file_is_executable(path_name)


def file_is_dll_client(
        path_name):
    """
    .. todo::

       Document.

    """
    file_is_dll_client_by_platform = {
        "darwin": file_is_dll_client_unix,
        "linux2": file_is_dll_client_unix,
        "win32": file_is_dll_client_win32
    }
    return file_is_dll_client_by_platform[sys.platform](path_name)


### def remove_read_only_file(
###         function,
###         path_name,
###         excinfo):
###     """
###     .. todo::
### 
###        Document.
### 
###     """
###     assert function == os.remove, function
###     assert os.path.isfile(path_name) and not os.path.islink(path_name), \
###         path_name
### 
###     # The remove function couldn't remove a regular file.
###     # Check for readonly, if so, make writable, remove and return,
###     # otherwise fall through.
###     if not os.access(path_name, os.W_OK):
###         os.chmod(path_name, stat.S_IWRITE)
###         os.remove(path_name)
###         return
### 
###     # Still here? Dunno how to fix this.
###     raise excinfo[0], excinfo[1]
### 
### 
### def create_directory(
###         directory_path_name):
###     """
###     .. todo::
### 
###        Document.
### 
###     """
###     if not os.path.exists(directory_path_name):
###         os.mkdir(directory_path_name)
### 
### 
### def remove_directory(
###         directory_path_name):
###     """
###     .. todo::
### 
###        Document.
### 
###     """
###     # At least on Windows, when CMake configures a file and writes it to the
###     # binary directory, these files are readonly and Python cannot remove them
###     # without changing them to writables. The remove_read_only_file does that.
###     if os.path.exists(directory_path_name):
###         assert os.path.isdir(directory_path_name), directory_path_name
###         shutil.rmtree(directory_path_name, False, remove_read_only_file)
### 
### 
### def recreate_directory(
###         directory_path_name):
###     """
###     .. todo::
### 
###        Document.
### 
###     """
###     remove_directory(directory_path_name)
###     os.mkdir(directory_path_name)
###     assert os.path.isdir(directory_path_name), directory_path_name
### 
### 
### # def native_path_name(
### #         path_name):
### #     """
### #     .. todo::
### # 
### #        Document.
### # 
### #     """
### #     if sys.platform == "win32":
### #         path_name = devenv.process.execute2(
### #             "cygpath -m \"{}\"".format(path_name)).rstrip()
### #     return path_name
### 
### 
### def native_path_name_default(
###         path_name):
###     return path_name
### 
### 
### def native_path_name_cygwin(
###         path_name):
###     return devenv.process.execute2(
###         "cygpath -m \"{}\"".format(path_name)).rstrip()
### 
### 
### def native_path_name_msys(
###         path_name):
###     # Only handle absolute path names.
###     if not path_name[0] == "/":
###         return path_name
### 
###     # Path names are either rooted at the msys installation root, or at the
###     # 'global' root. In the latter case, the second character is the drive
###     # name.
###     # For now, assume that if the first directory name in the path is a single
###     # character, the path name is rooted at the global root.
###     if path_name[2] == "/":
###         return "{drive}:{path}".format(drive=path_name[1].upper(),
###             path=path_name[2:])
###     else:
###         # Assumes MinGW is installed in C:/MinGW ...
###         return "C:/MinGW{path}".format(path=path_name)
### 
### 
### def native_path_name_win32(
###         path_name):
###     native_path_name_by_os_type = {
###         "cygwin": native_path_name_cygwin,
###         "msys": native_path_name_msys
###     }
###     return native_path_name_by_os_type[os_type()](path_name)
### 
### 
### def native_path_name(
###         path_name):
###     native_path_name_by_platform = {
###         "darwin": native_path_name_default,
###         "linux2": native_path_name_default,
###         "win32" : native_path_name_win32
###     }
###     return native_path_name_by_platform[sys.platform](path_name)
### 
### 
### def shell_path_name_default(
###         path_name):
###     return path_name
### 
### 
### def shell_path_name_cygwin(
###         path_name):
###     return devenv.process.execute2(
###         "cygpath --unix \"{}\"".format(path_name)).rstrip()
### 
### 
### def shell_path_name_msys(
###         path_name):
###     assert False, "TODO: implement"
### 
### 
### def shell_path_name_win32(
###         path_name):
###     shell_path_name_by_os_type = {
###         "cygwin": shell_path_name_cygwin,
###         "msys": shell_path_name_msys
###     }
###     return shell_path_name_by_os_type[os_type()](path_name)
### 
### 
### def shell_path_name(
###         path_name):
###     shell_path_name_by_platform = {
###         "darwin": shell_path_name_default,
###         "linux2": shell_path_name_default,
###         "win32" : shell_path_name_win32
###     }
###     return shell_path_name_by_platform[sys.platform](path_name)



def file_names_in_root_of_directory(
        directory_path_name):
    """
    .. todo::

       Document.

    """
    directory_names = []
    file_names = []

    for triple in os.walk(directory_path_name, topdown=True):
        path_name = triple[0]
        relative_path_name = os.path.relpath(path_name, directory_path_name)

        if not os.path.dirname(relative_path_name):
            if relative_path_name == ".":
                file_names = triple[2]
            else:
                directory_names.append(relative_path_name)
    return directory_names, file_names


### def copy_different_or_equal_files(
###         source_directory_path_name,
###         destination_directory_path_name):
###     """
###     .. todo::
### 
###        Document.
### 
###     """
###     assert os.path.isdir(source_directory_path_name), \
###         source_directory_path_name
###     assert os.path.isdir(os.path.split(
###         destination_directory_path_name)[0]), destination_directory_path_name
###     if not os.path.isdir(destination_directory_path_name):
###         os.mkdir(destination_directory_path_name)
### 
###     for file_name in os.listdir(source_directory_path_name):
###         source_file_name = os.path.join(source_directory_path_name, file_name)
###         destination_file_name = os.path.join(destination_directory_path_name,
###             file_name)
### 
###         if os.path.isdir(source_file_name):
###             copy_different_or_equal_files(source_file_name,
###                 destination_file_name)
###         else:
###             assert (not os.path.exists(destination_file_name)) or \
###                 filecmp.cmp(source_file_name, destination_file_name), \
###                 "{} != {}".format(source_file_name, destination_file_name)
###             if os.path.islink(source_file_name):
###                 link_destination = os.readlink(source_file_name)
###                 assert (not os.path.exists(destination_file_name)) or \
###                     (os.path.islink(destination_file_name) and \
###                         os.readlink(destination_file_name) == link_destination)
###                 if not os.path.exists(destination_file_name):
###                     os.symlink(link_destination, destination_file_name)
###             else:
###                 shutil.copy2(source_file_name, destination_file_name)
### 
###     shutil.copystat(source_directory_path_name, destination_directory_path_name)
### 
### def make_absolute(
###         path_names):
###     return [os.path.abspath(path_name) for path_name in path_names]
