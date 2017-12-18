import functools
import sys
import traceback
from .filesystem import *
from .pathname import *
from .package import *
from .shared_libraries import *


def checked_call(
        function):
    @functools.wraps(function)
    def wrapper(
            *args,
            **kwargs):
        result = 0
        try:
            result = function(*args, **kwargs)
        except:
            traceback.print_exc(file=sys.stderr)
            result = 1
        return 0 if result is None else result
    return wrapper
