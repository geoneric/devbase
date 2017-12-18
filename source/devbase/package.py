"""
Module with package related functionality.
"""
import os
import re
import sys
from . import filesystem
from . import process
from . import shared_libraries
# import devenv.path_names
# import devenv.process
# import devenv.project
# import devenv.shared_libraries


### def cpack_archive_generator_name():
###     """
###     .. todo::
### 
###        Document.
### 
###     """
###     return "ZIP" if sys.platform == "win32" else "TGZ"


def check_existance_of_root_directories(
        directory_names,
        required_directory_names):
    """
    .. todo::

       Document.

    """
    for directory_name in required_directory_names:
        if not directory_name in directory_names:
            raise RuntimeError(
                "Directory {0} missing from installation".format(
                    directory_name))

    if len(required_directory_names) < len(directory_names):
        raise RuntimeError(
            "Too many directories in root of installation: {0}".format(
                ", ".join(set(directory_names) -
                    set(required_directory_names))))


def check_existance_of_root_files(
        file_names,
        required_file_names):
    """
    .. todo::

       Document.

    """
    for file_name in required_file_names:
        if not file_name in file_names:
            raise RuntimeError(
                "File {0} missing from installation".format(file_name))

    if len(required_file_names) < len(file_names):
        raise RuntimeError(
            "Too many files in root of installation: {0}".format(
                ", ".join(set(file_names) -
                    set(required_file_names))))


def check_existance_of_directories(
        prefix,
        path_names):
    """
    .. todo::

       Document.

    """
    for path_name in path_names:
        if not os.path.isdir(os.path.join(prefix, path_name)):
            raise RuntimeError(
                "Directory {} missing from installation".format(path_name))


def check_existance_of_files(
        prefix,
        path_names):
    """
    .. todo::

       Document.

    """
    for path_name in path_names:
        if not os.path.isfile(os.path.join(prefix, path_name)):
            raise RuntimeError(
                "File {0} missing from installation".format(path_name))


def check_shared_libraries(
        target_path_names):
    """
    .. todo::

       Document.

    """
    shared_library_path_names, _ = \
        shared_libraries.shared_library_dependencies(target_path_names)
    # TODO
    ### _, external_shared_library_path_names, _ = \
    ###     shared_libraries.split_shared_library_path_names(
    ###         shared_library_path_names)
    ### if external_shared_library_path_names:
    ###     raise RuntimeError(
    ###         "The folowing 3rd party libraries are missing from the package:\n"
    ###         "{}".format("\n".join(external_shared_library_path_names)))
    ### if not sys.platform == "win32":
    ###     for shared_library_path_name in external_shared_library_path_names:
    ###         if not filesystem.file_is_executable(
    ###                 shared_library_path_name):
    ###             raise RuntimeError(
    ###                 "Shared library {} is not executable".format(
    ###                     shared_library_path_name))


def check_executables(
        path_names):
    for path_name in path_names:
        if not filesystem.file_is_executable(path_name):
            raise RuntimeError(
                "Shared library {} is not executable".format(path_name))

    dynamically_linked_executable_path_names = [path_name for path_name in
        path_names if filesystem.file_is_dynamically_linked(path_name)]
    check_shared_libraries(dynamically_linked_executable_path_names)


### def unpack_command(
###         package_path_name):
###     """
###     Unpack the package whose path name is passed in.
### 
###     :param package_path_name: Path name of package to unpack.
### 
###     Based on the file extension, a command is selected to unpack the package.
###     """
###     extension = os.path.splitext(package_path_name)[1]
###     if package_path_name.endswith(".tar.gz"):
###         extension = ".tar.gz"
### 
###     format_name_by_extension = {
###         ".zip": "zip",
###         ".tar.gz": "tgz"
###     }
### 
###     format_name = format_name_by_extension[extension]
### 
###     command_by_format_name = {
###         "tgz": "tar zxf {}".format(package_path_name),
###         "zip": "unzip {}".format(package_path_name)
###     }
### 
###     return command_by_format_name[format_name]
### 
### 
### def package_extension(
###         package_generator_name):
###     """
###     .. todo::
### 
###        Document.
### 
###     """
###     package_generator_name = package_generator_name.lower()
###     if package_generator_name == "tgz":
###         result = ".tar.gz"
###     elif package_generator_name == "zip":
###         result = ".zip"
###     else:
###         assert False, "unhandled package generator: {}".format(
###             package_generator_name)
###     return result
### 
### 
### def package_os_name():
###     """
###     .. todo::
### 
###        Document.
### 
###     """
###     os_name_by_platform = {
###         "linux2": "Linux",
###         "darwin": "Darwin",
###         "win32" : "Windows"
###     }
###     return os_name_by_platform[sys.platform]
### 
### 
### def cmake_variable_value(
###         script,
###         variable_name):
###     """
###     Return the value of a variable set in a CMake script.
###     """
###     # This assumes the variable's SET statement occupies a single line.
###     # match = re.search(r"^\s*set\({}\s+(\w+)\s*\)\s*$".format(variable_name),
###     #     script, re.IGNORECASE)
###     match = re.search(r"set\({}\s+(\w+)\s*\)".format(variable_name),
###         script, re.IGNORECASE)
###     return match.group(1) if not match is None else ""
### 
### 
### def package_version_string(
###         project_name,
###         project_file_contents_):
###     """
###     .. todo::
### 
###        Document.
### 
###     """
###     major_version = cmake_variable_value(project_file_contents_,
###         "{}_major_version".format(project_name))
###     assert major_version, major_version
###     minor_version = cmake_variable_value(project_file_contents_,
###         "{}_minor_version".format(project_name))
###     assert minor_version, minor_version
###     patch_version = cmake_variable_value(project_file_contents_,
###         "{}_patch_version".format(project_name))
###     assert patch_version, patch_version
###     return "{}.{}.{}".format(major_version, minor_version, patch_version)
### 
### 
### def package_build_stage(
###         project_name,
###         project_file_contents_):
###     """
###     .. todo::
### 
###        Document.
### 
###     """
###     return cmake_variable_value(project_file_contents_,
###         "{}_build_stage".format(project_name))
### 
### 
### def package_base_name(
###         project_name):
###     """
###     .. todo::
### 
###        Document.
### 
###     """
###     project_file_contents_ = project.project_file_contents(project_name)
###     base_name = cmake_variable_value(project_file_contents_,
###         "cpack_package_name")
###     if not base_name:
###         base_name = path_names.project_name_from_project_name(
###             project_name)
###     version = package_version_string(project_name, project_file_contents_)
###     build_stage = package_build_stage(project_name, project_file_contents_)
###     build_stage = "-{}".format(build_stage) if build_stage else ""
###     architecture = project.platform()[1]
###     # eg: Aguila-1.2.0-alpha5-Linux-x86_64
###     return "{name}-{version}{build_stage}-{os}-{architecture}".format(
###         name=base_name, version=version, build_stage=build_stage,
###         os=package_os_name(), architecture=architecture)
### 
### 
### def package_base_names(
###         project_names):
###     """
###     .. todo::
### 
###        Document.
### 
###     """
###     return [package_base_name(project_name) for project_name in project_names]
### 
### 
### def package_path_name(
###         project_name,
###         build_type,
###         package_generator_name):
###     """
###     .. todo::
### 
###        Document.
### 
###     """
###     binary_directory_path_name = \
###         path_names.project_binary_directory_path_name(project_name,
###             build_type)
###     package_name = "{}{}".format(
###         package_base_name(project_name),
###         package_extension(package_generator_name))
###     return os.path.join(binary_directory_path_name, package_name)
### 
### 
### def package_path_names(
###         project_names,
###         build_type,
###         package_generator_name):
###     """
###     .. todo::
### 
###        Document.
### 
###     """
###     return [package_path_name(project_name, build_type, package_generator_name)
###         for project_name in project_names]
### 
### 
### def build_package(
###         project_name,
###         package_generator_name,
###         build_type):
###     """
###     .. todo::
### 
###        Document.
### 
###     """
###     binary_directory_path_name = \
###         path_names.project_binary_directory_path_name(project_name,
###             build_type)
###     command = "cpack -G {} -C {}".format(package_generator_name,
###         build_type)
###     output = process.execute2(command,
###         working_directory=binary_directory_path_name)
###     sys.stdout.write(output)
### 
### 
### def build_packages(
###         project_names,
###         package_generator_name,
###         build_type):
###     """
###     .. todo::
### 
###        Document.
### 
###     """
###     for project_name in project_names:
###         build_package(project_name, package_generator_name, build_type)
### 
### 
### def unpack_package(
###         package_path_name,
###         directory_path_name):
###     """
###     .. todo::
### 
###        Document.
### 
###     """
###     assert os.path.isdir(directory_path_name)
###     command = unpack_command(package_path_name)
###     process.execute(command, working_directory=directory_path_name)
### 
### 
### def unpack_packages(
###         package_path_names,
###         directory_path_name):
###     """
###     .. todo::
### 
###        Document.
### 
###     """
###     for package_path_name in package_path_names:
###         unpack_package(package_path_name, directory_path_name)
### 
### 
### def merge_packages(
###         source_package_directory_path_names,
###         destination_package_directory_path_name):
###     """
###     .. todo::
### 
###        Document.
### 
###     """
###     assert not os.path.exists(destination_package_directory_path_name), \
###         destination_package_directory_path_name
### 
###     for source_package_directory_path_name in \
###             source_package_directory_path_names:
###         filesystem.copy_different_or_equal_files(
###             source_package_directory_path_name,
###             destination_package_directory_path_name)


def check_python_package(
        directory_path_name,
        package_name):
    """
    .. todo::

       Document.

    """
    assert os.path.isdir(directory_path_name), directory_path_name
    command = "python -E -c \"import {}\"".format(package_name)
    process.execute(command, working_directory=directory_path_name)
    # subprocess.check_call(["python", "-c", "import {}".format(package_name)])


def check_python_packages(
        directory_path_name,
        package_names):
    """
    .. todo::

       Document.

    """
    for package_name in package_names:
        check_python_package(directory_path_name, package_name)


def check_existance_of_files_and_directories(
        prefix,
        required_root_directory_names,
        required_root_file_names,
        required_directory_path_names,
        required_file_path_names):
    """
    .. todo::

       Document.

    """
    assert(os.path.isabs(prefix))

    if not os.path.isdir(prefix):
        raise ValueError(
            "Path to installation directory does not exist or is not "
            "a directory")

    try:
        root_directory_names, root_file_names = \
            filesystem.file_names_in_root_of_directory(prefix)
        check_existance_of_root_directories(root_directory_names,
            required_root_directory_names)
        check_existance_of_root_files(root_file_names, required_root_file_names)
        check_existance_of_directories(prefix, required_directory_path_names)
        check_existance_of_files(prefix, required_file_path_names)
    except Exception as exception:
        raise RuntimeError("Error verifying installation in {}\n{}".format(
            prefix, str(exception)))


def verify_package(
        prefix,
        required_root_directory_names,
        required_root_file_names,
        required_directory_path_names,
        required_file_path_names,
        executable_path_names,
        # shared_library_path_names,
        python_package_directory_name=None,
        python_package_names=None):
    """
    .. todo::

       Document.

    """
    check_existance_of_files_and_directories(prefix,
        required_root_directory_names, required_root_file_names,
        required_directory_path_names, required_file_path_names)
    executable_path_names = [os.path.join(prefix, path_name) for path_name in \
        executable_path_names]

    if sys.platform == "win32":
        path = os.environ["PATH"]
        os.environ["PATH"] = "{};{}".format(os.path.join(prefix, "lib"), path)
    check_executables(executable_path_names)
    if sys.platform == "win32":
        os.environ["PATH"] = path

    if python_package_directory_name:
        check_python_packages(os.path.join(prefix,
            python_package_directory_name), python_package_names)
