#!/bin/bash
set -e

mypwd=`pwd`

sudo apt-get update -qq
sudo apt-get remove -qq -y mingw32
sudo apt-get install -q -y mingw-w64
sudo apt-get install -q -y mingw-w64 g++-mingw-w64 gcc-mingw-w64 gfortran-mingw-w64

VERSION=1.8.4

wget http://www.coin-or.org/Tarballs/Bonmin/Bonmin-$VERSION.tgz
tar -xvf Bonmin-$VERSION.tgz
pushd Bonmin-$VERSION
pushd ThirdParty
#pushd ASL && ./get.ASL && popd
pushd Blas && ./get.Blas && popd 
pushd Lapack && ./get.Lapack && popd 
pushd Metis && ./get.Metis && popd 
pushd Mumps && ./get.Mumps && popd
popd
mkdir build
pushd build
../configure --host i686-w64-mingw32 --build mingw32 --prefix=/home/travis/bonmin-install --disable-shared ADD_FFLAGS=-fPIC ADD_CFLAGS=-fPIC ADD_CXXFLAGS=-fPIC --with-blas=BUILD --with-lapack=BUILD --with-mumps=BUILD --with-metis=BUILD --without-hsl --without-asl
make
make install
popd && popd
tar -zcvf bonmin_mingw32.tar.gz -C /home/travis/bonmin-install .
export PYTHONPATH="$PYTHONPATH:$mypwd/helpers" && python -c "from restricted import *; upload('bonmin_mingw32.tar.gz')"


