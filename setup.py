from distutils.core import setup
from Cython.Build import cythonize
from distutils.core import Extension

libs = ["openal", "xmp"]
args = ["-w"]

extensions = [Extension("xmpylayer", sources=["xmpylayer.pyx"], libraries=libs, extra_compile_args=args)]
setup(ext_modules = cythonize(extensions))
