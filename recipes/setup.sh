#!/bin/bash
set -e -E

source shellhelpers

ssh-keyscan github.com >> ~/.ssh/known_hosts
ssh-keyscan web.sourceforge.net >> ~/.ssh/known_hosts
ssh-keyscan shell.sourceforge.net >> ~/.ssh/known_hosts


export PATH=$HOME/.local/bin:$PATH
pip install --user requests==2.6.0
set -e -E
pip install --user psutil
echo $?
pip install --user pyaml
openssl aes-256-cbc -k "$keypass" -in id_rsa_travis.enc -out id_rsa_travis -d
openssl aes-256-cbc -k "$keypass" -in testbotcredentials.py.enc -out testbotcredentials.py -d
openssl aes-256-cbc -k "$keypass" -in env.sh.enc -out env.sh -d
chmod 600 id_rsa_travis

cat <<EOF >> ~/.ssh/config
Host github.com
        Hostname github.com
        User git
        IdentityFile $(pwd)/id_rsa_travis
EOF

git clone git@github.com:jgillis/restricted.git
git config --global user.email "testbot@casadidev.org"
git config --global user.name "casaditestbot"

if [ -d $HOME/build/testbot/recipes ];
then
  export TESTBOT_DIR=$HOME/build/testbot
else
  export TESTBOT_DIR=$HOME/build/casadi/testbot
fi
export RECIPES_DIR=$TESTBOT_DIR/recipes

function try_fetch_tar () {
  echo "Fetching $1 -> $2"
  travis_retry $RECIPES_DIR/fetch.sh $1.tar.gz && mkdir -p $2 && tar -xf $1.tar.gz -C $2 && rm $1.tar.gz
}

function try_fetch_zip() {
  travis_retry $RECIPES_DIR/fetch.sh $1.zip && mkdir -p $2 && unzip $1.zip -d $2 && rm $1.zip
}

function fetch_generic() {
  export GCCSUFFIX=""
  if [ -n "$SLURP_GCC" ];
  then
    GCCSUFFIX="_gcc${SLURP_GCC}"
  fi
  export BAKESUFFIX=""
  echo "Checking for $RECIPES_DIR/$1.yaml"
  if [ -f $RECIPES_DIR/$1.yaml ];
  then
    if [ -d $HOME/build/casadi/binaries/casadi ];
    then
      export BAKEVERSION=`python $HOME/build/testbot/helpers/gitmatch.py $RECIPES_DIR/$1.yaml $HOME/build/casadi/binaries/casadi`
    else
      export BAKEVERSION=`python $HOME/build/testbot/helpers/gitmatch.py $RECIPES_DIR/$1.yaml $HOME/build/casadi/casadi`
    fi
    echo "For $1, choosing bake version $BAKEVERSION" 
    BAKESUFFIX="_bake${BAKEVERSION}"
  else
    echo "Null bake"
  fi
  try_fetch_$3 $1_$2${GCCSUFFIX}${BAKESUFFIX} $1 || try_fetch_$3 $1_$2${BAKESUFFIX} $1
  unset BAKESUFFIX;export BAKESUFFIX
  unset GCCSUFFIX;export GCCSUFFIX
  unset BAKEVERSION;export BAKEVERSION
}

function fetch_tar() {
  fetch_generic $1 $2 "tar"
}

function fetch_zip() {
  fetch_generic $1 $2 "zip"
}
  
function slurp() {
  export SUFFIX_BACKUP=$SUFFIX
  export SUFFIXFILE_BACKUP=$SUFFIXFILE
  if [ -f $RECIPES_DIR/$1_${SLURP_CROSS}${BITNESS}_${SLURP_OS}.sh ];
  then
    echo 123;
    SETUP=1 source $RECIPES_DIR/$1_${SLURP_CROSS}${BITNESS}_${SLURP_OS}.sh
  elif [ -f $RECIPES_DIR/$1_${SLURP_CROSS}_${SLURP_OS}.sh ];
  then
    echo 456;
    SETUP=1 source $RECIPES_DIR/$1_${SLURP_CROSS}_${SLURP_OS}.sh
  elif [ -f $RECIPES_DIR/$1_${SLURP_OS}.sh ];
  then
    echo 678;
    SETUP=1 source $RECIPES_DIR/$1_${SLURP_OS}.sh
  else
    echo 101;
    echo "$RECIPES_DIR/$1_${SLURP_OS}.sh"
    SETUP=1 source $RECIPES_DIR/$1.sh
  fi
  export SUFFIX=$SUFFIX_BACKUP
  export SUFFIXFILE=$SUFFIXFILE_BACKUP
}

function slurp_put() {
  VERSIONSUFFIX=""
  if [ -n "$GCCVERSION" ];
  then
    VERSIONSUFFIX="${VERSIONSUFFIX}_gcc${GCCVERSION}"
  fi
  if [ -n "${BAKEVERSION}" ];
  then
    echo "here :$BAKEVERSION:"
    VERSIONSUFFIX="${VERSIONSUFFIX}_bake${BAKEVERSION}"
  fi
  export PYTHONPATH="$PYTHONPATH:$TESTBOT_DIR/helpers:$TESTBOT_DIR"
  python -c "from restricted import *; upload('$1.tar.gz','$1$VERSIONSUFFIX.tar.gz')" || python -c "from restricted import *; upload('$1.zip','$1$VERSIONSUFFIX.zip')"
  unset VERSIONSUFFIX;export VERSIONSUFFIX
}

export RECIPES_FOLDER="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function matlabtunnel() {
  source $TESTBOT_DIR/restricted/env.sh
  sudo bash -c "echo -e '\n127.0.0.1	$FLEX_SERVER\n' >> /etc/hosts;echo '127.0.0.1	$FLEX_HOSTNAME\n' >> /etc/hosts"
  cat /etc/hosts
  sudo hostname $FLEX_HOSTNAME
  mkdir -p ~/.matlab/${MATLABRELEASE}_licenses/
  echo -e "SERVER $FLEX_SERVER ANY 1725\nUSE_SERVER" > ~/.matlab/${MATLABRELEASE}_licenses/license.lic
  ssh-keyscan $GATE_SERVER >> ~/.ssh/known_hosts
  ssh -i $TESTBOT_DIR/id_rsa_travis $USER_GATE@$GATE_SERVER -L 1701:$FLEX_SERVER:1701 -L 1719:$FLEX_SERVER:1719 -L 1718:$FLEX_SERVER:1718 -L 2015:$FLEX_SERVER:2015 -L 1815:$FLEX_SERVER:1815 -L 1725:$FLEX_SERVER:1725 -L 27000:$FLEX_SERVER:27000 -N &
  sleep 3
}
