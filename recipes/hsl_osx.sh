#!/bin/bash
set -e

if [ -z "$SETUP" ]; then
  sudo apt-get install -y libblas-dev liblapack-dev
  mypwd=`pwd`
  pushd restricted
  wget http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/OLD/metis-4.0.3.tar.gz
  tar -xvf coinhsl.tar.gz
  cd coinhsl-2014.01.10
  tar -xvf ../metis-4.0.3.tar.gz
  ./configure --prefix=$mypwd/coinhsl-install LIBS="-llapack" --with-blas="-L/usr/lib -lblas" CXXFLAGS="-g -O2 -fopenmp" FCFLAGS="-g -O2 -fopenmp"
  make
  make install
  cd $mypwd/coinhsl-install/lib
  ln -s libcoinhsl.so libhsl.so
  popd
  tar -zcvf hsl_osx.tar.gz -C $mypwd/coinhsl-install/lib . 

  slurp_put hsl_osx
else
  fetch_tar hsl osx
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HOME/build/hsl
  export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/build/hsl
fi
