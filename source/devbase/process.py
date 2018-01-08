import os
import subprocess
import sys


def execute(
        command,
        working_directory=os.getcwd()):

    try:
        result = subprocess.run(
            command, shell=False, cwd=working_directory, check=True,
            universal_newlines=True,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    except subprocess.CalledProcessError as exception:

        sys.stderr.write("{}\n".format(exception))
        sys.stderr.write("{}\n".format(exception.stdout))
        sys.stderr.write("{}\n".format(exception.stderr))
        sys.stderr.flush()
        raise

    return result.stdout
