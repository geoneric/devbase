"""
Utilities related to shared libraries.
"""
import csv
import os.path
import subprocess
import sys
import tempfile
from .import filesystem
from .import pathname
from .import process


def determine_shared_library_dependencies_win32(
        executable_name):
    """
    .. todo::

       Document.

    """
    shared_library_path_names = []
    missing_shared_library_names = []
    walker_result_file = tempfile.NamedTemporaryFile(delete=False)
    walker_result_filename = walker_result_file.name.replace("\\", "/")
    del walker_result_file

    # Assume depends.exe can be found in PATH.
    options = ["/c", "/a:0", "/f:1", "/u:0", "/ps:0", "/pp:0", "/po:0",
        "/ph:0", "/pl:0", "/pg:0", "/pt:0", "/pn:0", "/pe:0", "/pm:0",
        "/pf:1", "/pi:0", "/pc:0", "/pa:0",
        "/oc:{}".format(walker_result_filename)
    ]
    command = "depends.exe {} {}".format(" ".join(options),
        executable_name.replace("\\", "/"))

    try:
        # This command fails in case some dlls cannot be found. Until now
        # these are the dlls listed below. Assume that is still te case
        # (when in doubt, check the generated temp file).
        process.execute(command)
    except:
        print("Dependency Walker found errors, but continuing anyway ...")

    # processing_error_flag = int("00010000", 2)
    # module_error_flag = int("00000100", 2)
    # runtime_problem_flag = int("00000001", 2)

    # def bin(s):
    #     return str(s) if s<=1 else bin(s>>1) + str(s&1)

    # print "processing error >=", bin(processing_error_flag)
    # print "module error >=    ", bin(module_error_flag)
    # print "runtime problem >= ", bin(runtime_problem_flag)
    # print "result             ", bin(result)

    # if result != 10:
    #     raise RuntimeError(
    #         "Error executing command:\n{}\n"
    #         "See {} for more info\n"
    #         "depends.exe exit code: {} (see {})".format(
    #             command, walker_result_filename, bin(result),
    #             "http://www.dependencywalker.com/help/html/"
    #             "hidr_command_line_help.htm"))

    known_missing_shared_library_filenames = [
        # win64
        "ieshims.dll",
        "dcomp.dll",
        "gpsvc.dll",

        "devicelockhelpers.dll",
        "emclient.dll",

        # win32
        "c:\windows\system32\gpsvc.dll",
        "c:\windows\system32\sysntfy.dll"

    ]
    known_missing_shared_library_name_prefixes = [
        "api-ms-win",
        "ext-ms-",
    ]


    # Read depends output and pick our libraries.
    with open(walker_result_filename, "r") as csv_file:
        reader = csv.reader(csv_file)
        header = next(reader, "whatever")
        for row in reader:
            shared_library_path_name = row[1].lower()
            # Skip some Windows dlls, listed above
            # Skip some Windows dlls from some directories listed above
            # Skip python library. We never want to ship it
            # Depends add the executable name itself in the output. Skip it.
            if (not shared_library_path_name in \
                    known_missing_shared_library_filenames) and \
                    (not any([shared_library_path_name.startswith(prefix) for prefix in known_missing_shared_library_name_prefixes])) and \
                    (shared_library_path_name.find("python35.dll") == -1) and \
                    (shared_library_path_name.find("python36.dll") == -1) and \
                    (not pathname.path_names_are_equal(shared_library_path_name, executable_name)):

                if not os.path.exists(shared_library_path_name):
                    missing_shared_library_names.append(
                        shared_library_path_name)
                else:
                    shared_library_path_names.append(
                        shared_library_path_name)

    os.remove(walker_result_filename)
    assert not os.path.exists(walker_result_filename), walker_result_filename
    return shared_library_path_names, missing_shared_library_names


def determine_shared_library_dependencies_darwin(
        executable_name):
    """
    .. todo::

       Document.

    """
    command = "otool -L {}".format(executable_name)
    output = devenv.process.execute2(command).strip().split("\n")
    shared_library_path_names = []
    missing_shared_library_names = []

    # In case executable is an executable, we should start at output[1].
    # In case executable is a dll, we should start at output[2], because now
    # output[1] contains the install name of the dll.
    # TODO Is it guaranteed to be the first one? Can we skip it based on
    #      the value instead on position?
    # First test for file_is_shared_library because shared libraries can be
    # executable.
    for line in output[2:] if devenv.filesystem.file_is_shared_library(
            executable_name) else output[1:]:
        parts = line.split("(compatibility")
        assert len(parts) == 2, parts
        shared_library_path_name = parts[0].strip()

        # Skip python library. We never want to ship it.
        if shared_library_path_name.find("libpython") == -1:
            shared_library_path_name = shared_library_path_name.replace(
                "@loader_path", os.path.split(executable_name)[0])

            if not os.path.exists(shared_library_path_name):
                missing_shared_library_names.append(shared_library_path_name)
            else:
                shared_library_path_names.append(shared_library_path_name)

    return shared_library_path_names, missing_shared_library_names


def determine_shared_library_dependencies_linux(
        executable_name):
    """
    .. todo::

       Document.

    """
    command = "ldd {}".format(executable_name)
    output = devenv.process.execute2(command).split("\n")
    shared_library_path_names = []
    missing_shared_library_names = []

    for line in output:
        parts = line.split("=>")
        assert len(parts) <= 2
        name = parts[0].strip()
        path = ""

        if len(parts) == 2:
            path = parts[1].strip()

        # Filter out any line that is not formatted like:
        #   <shared lib name> => <path to shared lib> (<address>)
        # Assume anything else is not interesting.
        if len(path) and path.find(" ") != -1:
            if path != "not found":
                # Don't use realpath. We want the same name as is written in
                # the dll client.
                # path = os.path.realpath(path.split()[0])
                path = path.split()[0]

                # Skip python library. We never want to ship it.
                if path.lower().find("libpython") == -1:
                    shared_library_path_names.append(path)
            else:
                missing_shared_library_names.append(name)

    # In case the dll client depends on the Qt GUI libraries, we must add
    # the QtDBus dll. On KDE platforms, this dll is loaded at runtime, so
    # it won't show up in ldd's list. But it is used and it might result in
    # crashes due to different versions between QtDBus and the other Qt dlls.
    # This all doesn't count on lsb-platforms.
    if not devenv.project.lsb_platform():
        for shared_library_path_name in shared_library_path_names:
            directory_name, base_name = os.path.split(shared_library_path_name)
            if base_name.find("QtGui") != -1:
                qt_dbus_shared_library_path_name = os.path.join(directory_name,
                    base_name.replace("QtGui", "QtDBus"))
                assert os.path.exists(qt_dbus_shared_library_path_name)
                shared_library_path_names.append(
                    qt_dbus_shared_library_path_name)
                break

    return shared_library_path_names, missing_shared_library_names


def determine_shared_library_dependencies(
        path_name):
    """
    .. todo::

       Document.

    """
    assert os.path.isfile(path_name), path_name
    # assert os.path.isabs(path_name), path_name
    assert filesystem.file_is_dll_client(path_name), path_name
    dispatch_by_platform = {
        "win32": determine_shared_library_dependencies_win32,
        "darwin": determine_shared_library_dependencies_darwin,
        "linux2": determine_shared_library_dependencies_linux
    }
    return dispatch_by_platform[sys.platform](path_name)


### def split_shared_library_path_names(
###         shared_library_path_names):
###     """
###     Split library path names based on whether they are provided by the OS or
###     by the package.
###     """
###     package_shared_library_path_names = []
###     external_shared_library_path_names = []
###     system_shared_library_path_names = []
### 
###     objects_directory_path_name = \
###         pathname.objects_directory_path_name() if "OBJECTS" in \
###             os.environ else None
###     pcrteam_extern_directory_path_name = os.path.realpath(
###         pathname.pcrteam_extern_directory_path_name())
### 
###     for shared_library_path_name in shared_library_path_names:
###         directory_path_name = os.path.dirname(shared_library_path_name)
### 
###         if objects_directory_path_name and \
###                 pathname.path_names_are_equal(
###                     pathname.commonprefix([objects_directory_path_name,
###                         directory_path_name]),
###                 objects_directory_path_name):
###             package_shared_library_path_names.append(shared_library_path_name)
###         elif pathname.path_names_are_equal(
###                 pathname.commonprefix(
###                     [pcrteam_extern_directory_path_name, directory_path_name]),
###                 pcrteam_extern_directory_path_name):
###             external_shared_library_path_names.append(shared_library_path_name)
###         else:
###             system_shared_library_path_names.append(shared_library_path_name)
### 
###     return system_shared_library_path_names, \
###         external_shared_library_path_names, package_shared_library_path_names


### def print_iterable(
###         description,
###         iterable):
###     """
###     .. todo::
### 
###        Document.
### 
###     """
###     print("{description}({nr_items}):\n  {iterable}".format(
###         description=description, nr_items=len(iterable),
###         iterable="\n  ".join(iterable)))
### 
### 
### def print_shared_library_dependencies(
###         shared_library_path_names,
###         missing_shared_library_names):
###     """
###     .. todo::
### 
###        Document.
### 
###     """
###     system_shared_library_path_names, external_shared_library_path_names, \
###         package_shared_library_path_names = split_shared_library_path_names(
###             shared_library_path_names)
### 
###     print_iterable("Libraries in the package",
###         package_shared_library_path_names)
###     print("")
###     print_iterable("Libraries not in the package",
###         external_shared_library_path_names)
###     print("")
###     print_iterable("Libraries provided by OS",
###         system_shared_library_path_names)
###     print("")
###     print_iterable("Missing libraries",
###         missing_shared_library_names)


def shared_library_dependencies(
        executable_names):
    """
    .. todo::

       Document.

    """
    shared_library_path_names = set()
    missing_shared_library_names = set()
    for executable_name in executable_names:
        shared_libraries, missing_shared_libraries = \
            determine_shared_library_dependencies(executable_name)
        shared_library_path_names = shared_library_path_names.union(
            shared_libraries)
        missing_shared_library_names = missing_shared_library_names.union(
            missing_shared_libraries)

    return shared_library_path_names, missing_shared_library_names


### def fixup_dll_client_darwin(
###         path_name,
###         project_prefix,
###         offset):
###     # TODO Also update the first install name. This one is currently skipped
###     #      because determine_shared_library_dependencies_darwin skips it.
### 
###     # Change the library identification name of the dll. Use the base
###     # name of the dll, otherwise it keeps pointing at paths on our dev
###     # machine, which is not terrible, but is sloppy. In essence, we
###     # are removing the directory path name here.
###     # command = "install_name_tool -id {} {}".format(os.path.basename(
###     #     path_name), path_name)
### 
###     # Put the absolute name as the id of the dll. This is needed so clients
###     # linking to the dll get this path in their list of install names. This
###     # makes it possible to use the client without setting DYLD_LIBRARY_PATH.
###     # This command is ignored if path_name doesn't point to a shared library.
###     command = "install_name_tool -id {} {}".format(path_name, path_name)
###     devenv.process.execute(command)
### 
###     # Change the install names of the shared libraries this dll client depends
###     # on.
###     shared_library_path_names, missing_shared_library_names = \
###         shared_library_dependencies([path_name])
###     # assert not missing_shared_library_names
### 
###     for current_install_name in shared_library_path_names:
###         new_install_name = os.path.join(os.path.split(path_name)[0], offset,
###             "lib", os.path.basename(current_install_name))
###         if os.path.exists(new_install_name):
###             install_name = "@loader_path/{}/lib/{}".format(offset,
###                 os.path.basename(current_install_name))
###             command = "install_name_tool -change {} {} {}".format(
###                 current_install_name, install_name, path_name)
###             devenv.process.execute(command)
### 
###             # Fixup the dll itself.
###             fixup_dll_client_darwin(os.path.realpath(new_install_name),
###                 project_prefix, "..")
### 
###     for current_install_name in missing_shared_library_names:
###         new_install_name = os.path.join(os.path.split(path_name)[0], offset,
###             "lib", current_install_name)
###         assert os.path.exists(new_install_name), new_install_name
###         if os.path.exists(new_install_name):
###             install_name = "@loader_path/{}/lib/{}".format(offset,
###                 os.path.basename(current_install_name))
###             command = "install_name_tool -change {} {} {}".format(
###                 current_install_name, install_name, path_name)
###             devenv.process.execute(command)
### 
###             # Fixup the dll itself.
###             fixup_dll_client_darwin(os.path.realpath(new_install_name),
###                 project_prefix, "..")
### 
### 
### def fixup_dll_client_linux(
###         path_name,
###         project_prefix,
###         offset):
###     rpath = "\$ORIGIN/{}/lib".format(offset)
###     command = "chrpath --replace {} {}".format(rpath, path_name)
###     devenv.process.execute(command)


def fixup_dll_client_win32(
        path_name,
        project_prefix,
        offset):
    """
    path_name: Pathname of dll-client to fix.
    project_prefix: Path to root of project.
    offset: Relative path to root of project, eg: ../..
    """

    # Determine shared libraries this client depends on.
    shared_library_names, missing_shared_library_names = \
        shared_library_dependencies([os.path.join(project_prefix, path_name)])
    assert not missing_shared_library_names, path_name

    # Skip those shared libraries that are not located in the prefix. These
    # are assumed to be provided by the system.
    shared_library_names = [dll_file_name for dll_file_name in \
            shared_library_names if
        pathname.path_names_are_equal(
            pathname.commonprefix([dll_file_name, project_prefix]),
            project_prefix)]


    # For each client not in the lib directory:
    # - Create an application configuration containing an offset to the lib
    #   directory with all the dll assemblies.
    # - Create an application manifest with references to the private dll
    #   assemblies in the lib directory. Insert this manifest in the client.

    # For each 'local' dll the client depends on:
    # - Create a private assembly if it not already exists.

    ### # Determine processorArchitecture.
    ### # Hack.
    ### if "86-32" in project_prefix:
    ###     processor_architecture = "x86"
    ### elif "86-64" in project_prefix:
    ###     processor_architecture = "amd64"
    ### else:
    ###     assert False, project_prefix

    processor_architecture = "amd64"

    assembly_names = []
    files_to_delete = []

    # Make dll assemblies of each dll we store in <prefix>/lib.
    # - Create assembly manifest.
    # - Embed assembly manifest in dll (resource id 1).
    # - Create application manifest.
    # - Embed application manifest in dll (resource id 2).
    for dll_pathname in shared_library_names:
        assert os.path.splitext(dll_pathname)[1].lower() == ".dll", dll_pathname
        assert os.path.split(dll_pathname)[0].lower().endswith("lib")


        assembly_manifest_pathname = "{}.assembly.manifest".format(dll_pathname)
        dll_filename = os.path.split(dll_pathname)[1]
        assembly_name = os.path.splitext(dll_filename)[0]
        assembly_names.append(assembly_name)

        if not os.path.exists(assembly_manifest_pathname):
            with open(assembly_manifest_pathname, "w") as manifest:
                manifest.write("""\
<?xml version='1.0' encoding='UTF-8' standalone='yes'?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
  <assemblyIdentity name="{}" version="1.2.3.4" processorArchitecture="{}"  type="win32"/>
  <file name="{}"/>
</assembly>""".format(assembly_name, processor_architecture, dll_filename))

            # Validate manifest.
            command = "mt.exe -manifest {} -validate_manifest".format(
                assembly_manifest_pathname.replace("\\", "/"))
            process.execute(command)

            # Embed manifest.
            command = "mt -manifest {} -outputresource:{};1".format(
                assembly_manifest_pathname.replace("\\", "/"),
                dll_pathname.replace("\\", "/"))
            process.execute(command)
            files_to_delete.append(assembly_manifest_pathname)


        application_manifest_pathname = "{}.application.manifest".format(
            dll_pathname)

        if not os.path.exists(application_manifest_pathname):
            with open(application_manifest_pathname, "w") as manifest:
                manifest.write("""\
<?xml version='1.0' encoding='UTF-8' standalone='yes'?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
  <trustInfo xmlns="urn:schemas-microsoft-com:asm.v3">
    <security>
      <requestedPrivileges>
        <requestedExecutionLevel level='asInvoker' uiAccess='false' />
      </requestedPrivileges>
    </security>
  </trustInfo>
  <dependency>
    <dependentAssembly>
      <assemblyIdentity type='win32' name='Microsoft.VC90.CRT' version='9.0.21022.8' processorArchitecture='{}' publicKeyToken='1fc8b3b9a1e18e3b' />
    </dependentAssembly>
  </dependency>
</assembly>""".format(processor_architecture))

            # Validate manifest.
            command = "mt.exe -manifest {} -validate_manifest".format(
                application_manifest_pathname.replace("\\", "/"))
            # TODO: Fails with:
            # subprocess.CalledProcessError: Command 'mt.exe -manifest d:/jong0137/development/install/pcraster/lib/pcraster_aguila.dll.application.manifest -validate_manifest' returned non-zero exit status 31
            # process.execute(command)

            # Embed manifest.
            command = "mt -manifest {} -outputresource:{};2".format(
                application_manifest_pathname.replace("\\", "/"),
                dll_pathname.replace("\\", "/"))
            process.execute(command)
            files_to_delete.append(application_manifest_pathname)


    # This assembly stuff doesn't seem to work for Python extensions. They
    # are delay-loaded and so are the dlls they depend on.
    ### if os.path.split(path_name)[0].lower().endswith("bin") or \
    ###         os.path.splitext(path_name)[1].lower() == ".pyd":

    if os.path.split(path_name)[0].lower().endswith("bin"):

        # This is a requirement of the privatePath attribute of the
        # probing element of the application configuration.
        # https://msdn.microsoft.com/en-us/library/aa374182(VS.85).aspx
        assert len(offset.split("/")) <= 2, offset

        # Direct each exe and pyd to the directory with our dll assemblies.
        # Create application configuration.
        assert os.path.splitext(path_name)[1].lower() in [".exe", ".pyd"], \
            path_name
        configuration_pathname = "{}.config".format(path_name)
        with open(configuration_pathname, "w") as configuration:
            configuration.write("""\
<?xml version='1.0' encoding='UTF-8' standalone='yes'?>
<configuration>
  <windows>
    <assemblyBinding xmlns="urn:schemas-microsoft-com:asm.v1">
      <probing privatePath="{}/lib"/>
    </assemblyBinding>
  </windows>
</configuration>
""".format(offset))

        # Embed a manifest with the assembly dependencies in exe/pyd.
        # Create and embed application manifest.
        application_manifest_pathname = "{}.application.manifest".format(
            path_name)
        dependencies = ["""\
  <dependency>
    <dependentAssembly>
      <assemblyIdentity type="win32" name="{}" version="1.2.3.4" processorArchitecture="{}" language="*"/>
    </dependentAssembly>
  </dependency>""".format(assembly_name, processor_architecture) for
            assembly_name in assembly_names]

        with open(application_manifest_pathname, "w") as manifest:
            manifest.write("""\
<?xml version='1.0' encoding='UTF-8' standalone='yes'?>
<assembly xmlns='urn:schemas-microsoft-com:asm.v1' manifestVersion='1.0'>
  <trustInfo xmlns="urn:schemas-microsoft-com:asm.v3">
    <security>
      <requestedPrivileges>
        <requestedExecutionLevel level='asInvoker' uiAccess='false' />
      </requestedPrivileges>
    </security>
  </trustInfo>
  <dependency>
    <dependentAssembly>
      <assemblyIdentity type='win32' name='Microsoft.VC90.CRT' version='9.0.21022.8' processorArchitecture='{}' publicKeyToken='1fc8b3b9a1e18e3b' />
    </dependentAssembly>
  </dependency>
  {}
</assembly>""".format(processor_architecture, "\n".join(dependencies)))

        # Validate manifest.
        command = "mt.exe -manifest {} -validate_manifest".format(
            application_manifest_pathname.replace("\\", "/"))
        # TODO: Fails with:
        # subprocess.CalledProcessError: Command 'mt.exe -manifest d:/jong0137/development/install/pcraster/lib/pcraster_aguila.dll.application.manifest -validate_manifest' returned non-zero exit status 31
        # process.execute(command)

        # Embed manifest.
        command = "mt -manifest {} -outputresource:{};1".format(
            application_manifest_pathname.replace("\\", "/"),
            path_name.replace("\\", "/"))
        process.execute(command)
        files_to_delete.append(application_manifest_pathname)


    for file_to_delete in files_to_delete:
        os.remove(file_to_delete)


def fixup_dll_client(
        path_name,
        project_prefix):
    path_name = os.path.abspath(path_name)
    project_prefix = os.path.abspath(project_prefix)
    assert os.path.commonprefix([path_name, project_prefix]) == project_prefix
    offset = os.path.split(path_name[len(project_prefix) + 1:])[0]
    offset = pathname.path_name_components(offset)
    offset = "/".join([".." for name in offset])

    fixup_dll_client_by_platform = {
        # "darwin": fixup_dll_client_darwin,
        # "linux2": fixup_dll_client_linux,
        "win32": fixup_dll_client_win32
    }
    fixup_dll_client_by_platform[sys.platform](path_name, project_prefix, offset)


### # def print_shared_library_dependencies(
### #         executable_names):
### #     """
### #     .. todo::
### #
### #        Document.
### #
### #     """
### #     shared_library_path_names, missing_shared_library_names = \
### #         shared_library_dependencies(executable_names)
### #     print_shared_library_dependencies(shared_library_path_names,
### #         missing_shared_library_names)
### 
### 
### # def verify_shared_libraries_present(
### #         executable_names):
### #     for executable_name in executable_names:
### #         shared_libraries, missing_shared_libraries =
### #             determine_shared_library_dependencies(executable_name,
### #                 shell=False)
### #         assert not missing_shared_libraries, missing_shared_libraries
