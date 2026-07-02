#! /usr/bin/bash
set -e

# Bundled config.sub/config.guess predate aarch64 triplets -- replace with
# the current ones from the gnuconfig package before configuring.
for f in config.sub config.guess; do
  find . -name "$f" -exec cp "$BUILD_PREFIX/share/gnuconfig/$f" {} \;
done

if [ "$(uname)" = "Darwin" ]; then
  # std::unary_function/binary_function were removed from the standard in
  # C++17; Apple's libc++ enforces the removal unless this compatibility
  # macro opts back in (GNU libstdc++ still provides them, so linux is fine).
  export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_ENABLE_CXX17_REMOVED_UNARY_BINARY_FUNCTION"
fi

./configure --prefix=$PREFIX

make -j$(nproc)
make install
