#!/bin/sh

BUILDDIR=~/compil/llvm-build
SRCDIR=~/compil/llvm

mkdir -p $BUILDDIR
cd  $BUILDDIR
$SRCDIR/configure

make -j 7

sudo cp $BUILDDIR/Debug+Asserts/lib/libclang.so /usr/local/lib/
sudo ln -sf /usr/local/lib/libclang.so /usr/local/lib/libclang.so.1
# sudo ldconfig
