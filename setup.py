from distutils.core import setup
from Cython.Build import cythonize

setup(
    name = 'Clope clustering',
    ext_modules = cythonize("clope.pyx"),
)
