#! /usr/bin/bash
set -e

# Bundled config.sub/config.guess predate aarch64 triplets -- replace with
# the current ones from the gnuconfig package before configuring.
for f in config.sub config.guess; do
  find . -name "$f" -exec cp "$BUILD_PREFIX/share/gnuconfig/$f" {} \;
done

if [ "$(uname)" = "Darwin" ]; then
  # A grab-bag of C++98 STL functor-adaptor utilities was removed from the
  # standard in C++17 (unary_function/binary_function, and separately the
  # bind1st/bind2nd/pointer_to_{unary,binary}_function/mem_fun family).
  # Apple's libc++ enforces both removals unless opted back in; GNU
  # libstdc++ still ships them, so this is a no-op on linux.
  export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_ENABLE_CXX17_REMOVED_UNARY_BINARY_FUNCTION -D_LIBCPP_ENABLE_CXX17_REMOVED_BINDERS"

  # The bundled build system (~2010) mishandles Darwin's relocatable (-r)
  # partial-link step together with -rpath against modern Apple ld ("ld:
  # -rpath can only be used when creating a dynamic final linked image").
  # Its Makefiles also hardcode "aclocal-1.11" to rebuild aclocal.m4 when
  # macro files look newer -- a version that isn't installed here, so any
  # later timestamp-triggered regeneration fails with "aclocal-1.11:
  # command not found". Regenerate the whole build system from the
  # currently installed autotools instead of patching around each symptom.
  autoreconf -fi
fi

./configure --prefix=$PREFIX

# nproc doesn't exist on macOS; without a fallback, `make -j$(nproc)`
# silently becomes unbounded-parallelism `make -j`.
NPROC=$(nproc 2>/dev/null || sysctl -n hw.ncpu)
make -j$NPROC
make install
