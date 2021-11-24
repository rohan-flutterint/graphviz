#!/usr/bin/env bash

set -eux

/cygwinsetup.exe --quiet-mode --wait --packages autoconf2.5
/cygwinsetup.exe --quiet-mode --wait --packages automake
/cygwinsetup.exe --quiet-mode --wait --packages bison
/cygwinsetup.exe --quiet-mode --wait --packages cmake
/cygwinsetup.exe --quiet-mode --wait --packages flex
/cygwinsetup.exe --quiet-mode --wait --packages gcc-core
/cygwinsetup.exe --quiet-mode --wait --packages gcc-g++
/cygwinsetup.exe --quiet-mode --wait --packages libcairo-devel
/cygwinsetup.exe --quiet-mode --wait --packages libexpat-devel
/cygwinsetup.exe --quiet-mode --wait --packages libpango1.0-devel
/cygwinsetup.exe --quiet-mode --wait --packages libgd-devel
/cygwinsetup.exe --quiet-mode --wait --packages libtool
/cygwinsetup.exe --quiet-mode --wait --packages make
/cygwinsetup.exe --quiet-mode --wait --packages python3
/cygwinsetup.exe --quiet-mode --wait --packages zlib-devel

# setup Ccache to accelerate compilation
/cygwinsetup.exe --quiet-mode --wait --packages ccache
export CC="ccache ${CC:-cc}"
export CXX="ccache ${CXX:-c++}"

# use the libs installed with cygwinsetup instead of those in
# https://gitlab.com/graphviz/graphviz-windows-dependencies
export CMAKE_OPTIONS=-Duse_win_pre_inst_libs=OFF

ci/build.sh
