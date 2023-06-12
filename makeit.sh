#!/bin/bash

source scl_source enable devtoolset-8 


# exit when any command fails
#set -e

# Prints every command that is executed
#set -x

# keep track of the last executed command
#trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
#trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT


HERE=`pwd`
MGHOME=./MadGraph.3.3.2

PATH=$MGHOME/bin:$PATH

COMPILATIONDIR=$MGHOME/compilationdir

# Python stuff
PYTHON_VERSION=3.9.9
PYTHON39PATH=$MGHOME/python39

export PATH=$PYTHON39PATH/bin:$PATH
export LD_LIBRARY_PATH=$PYTHON39PATH/lib:$LD_LIBRARY_PATH


C_INCLUDE_PATH=$PYTHON39PATH/include/python3.9
CPLUS_INCLUDE_PATH=$PYTHON39PATH/include/python3.9


# CMake stuff - Skipped
CMAKE_VERSION=3.20.2


# HEP MC
HEPMC_VERSION=2.06.11

# FastJet
FASTJET_VERSION=3.3.4

#LHAPDF
LHAPDF_VERSION=6.3.0

# Pythia
PYTHIA_VERSION=8306

# BOOST
BOOST_VERSION=1.76.0

# MG
MG_VERSION=3.3.2
MG5aMC_PY8_INTERFACE_VERSION=1.3



function installpython() {
    mkdir $COMPILATIONDIR
    pushd $COMPILATIONDIR
    curl -sLO "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"
    tar -xzf "Python-${PYTHON_VERSION}.tgz"
    cd "Python-${PYTHON_VERSION}"
    source scl_source enable devtoolset-8
    ./configure --help
    ./configure --prefix=$PYTHON39PATH --exec_prefix=$PYTHON39PATH --with-ensurepip  --enable-shared  --enable-optimizations --with-lto --enable-ipv6
    make -j"$(($(nproc) - 1))"
    make install
    printf "\n# For Python 2.7 use 'python2'\n" >> ${HERE}/bashrc
    printf "# For Python 2.7 in shebangs use '\#\!/usr/libexec/platform-python'\n" >> ${HERE}/bashrc
    printf "\nsource scl_source enable devtoolset-8\n" >> ${HERE}/bash_profile
    LD_LIBRARY_PATH=$PYTHON39PATH/lib python3.9 -m venv $MGHOME
    . python39/lib/python3.9/venv/scripts/common/activate
    popd
    rm -rf $COMPILATIONDIR


    $PYTHON39PATH/bin/python3.9 -m pip install --upgrade pip
    $PYTHON39PATH/bin/pip3.9 install numpy
}

function installcmake() {
    yum install -y       gcc       gcc-c++       git       make
    mkdir $COMPILATIONDIR
    pushd $COMPILATIONDIR
 
    curl -sLO "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz"
    tar -xzf "cmake-${CMAKE_VERSION}.tar.gz"
    cd "cmake-${CMAKE_VERSION}"
    ./bootstrap
    make -j"$(($(nproc) - 1))"
    make install
    popd
    rm -rf $COMPILATIONDIR

    cmake --version # buildkit
}


function installHEPMC() {
    mkdir $COMPILATIONDIR
    pushd $COMPILATIONDIR

    wget http://hepmc.web.cern.ch/hepmc/releases/hepmc${HEPMC_VERSION}.tgz
    tar xvfz hepmc${HEPMC_VERSION}.tgz
    mv HepMC-${HEPMC_VERSION} src
    cmake3       -DCMAKE_CXX_COMPILER=$(command -v g++)       -DCMAKE_BUILD_TYPE=Release       -Dbuild_docs:BOOL=OFF       -Dmomentum:STRING=MEV       -Dlength:STRING=MM       -DCMAKE_INSTALL_PREFIX=$MGHOME       -S src       -B build
    cmake3 build -L
    cmake3 --build build -- -j$(($(nproc) - 1))
    cmake3 --build build --target install

    popd
    rm -rf $COMPILATIONDIR


}


function installfastjet() {
    mkdir $COMPILATIONDIR
    pushd $COMPILATIONDIR

    wget http://fastjet.fr/repo/fastjet-${FASTJET_VERSION}.tar.gz
    tar xvfz fastjet-${FASTJET_VERSION}.tar.gz
    cd fastjet-${FASTJET_VERSION}
    ./configure --help
    export CXX=$(command -v g++)
    export PYTHON=$(command -v python3)
    export PYTHON_CONFIG=$(find $MGHOME/ -iname "python-config.py")
    ./configure       --prefix=$MGHOME       --enable-pyext=yes
    make -j$(($(nproc) - 1))
    make check
    make install

    popd
    rm -rf $COMPILATIONDIR
}


function installlhapdf() {
    mkdir $COMPILATIONDIR
    pushd $COMPILATIONDIR

    wget https://lhapdf.hepforge.org/downloads/?f=LHAPDF-${LHAPDF_VERSION}.tar.gz -O LHAPDF-${LHAPDF_VERSION}.tar.gz
    tar xvfz LHAPDF-${LHAPDF_VERSION}.tar.gz
    cd LHAPDF-${LHAPDF_VERSION}
    ./configure --help
    export CXX=$(command -v g++)
    export PYTHON=$(command -v python3)
    ./configure       --prefix=$MGHOME
    make -j$(($(nproc) - 1))
    make install

    popd
    rm -rf $COMPILATIONDIR
}


function installpythia() {
    mkdir $COMPILATIONDIR
    pushd $COMPILATIONDIR

    
    wget "https://pythia.org/download/pythia${PYTHIA_VERSION:0:2}/pythia${PYTHIA_VERSION}.tgz"
    tar xvfz pythia${PYTHIA_VERSION}.tgz
    cd pythia${PYTHIA_VERSION}
    cd include/Pythia8Plugins
    mv JetMatching.h JetMatching.h.orig
    wget "http://amcatnlo.web.cern.ch/amcatnlo/JetMatching.h" -O JetMatching.h
    cd ../../
    ./configure --help
    export PYTHON_MINOR_VERSION=${PYTHON_VERSION::3}
    ./configure       --prefix=$MGHOME       --arch=Linux       --cxx=g++       --enable-64bit       --with-gzip       --with-hepmc2=$MGHOME       --with-lhapdf6=$MGHOME       --with-fastjet3=$MGHOME       --with-python-bin=$MGHOME/bin/       --with-python-lib=$MGHOME/lib/python${PYTHON_MINOR_VERSION}       --with-python-include=$PYTHON39PATH/include/python${PYTHON_MINOR_VERSION}       --cxx-common="-O2 -m64 -pedantic -W -Wall -Wshadow -fPIC -std=c++11"       --cxx-shared="-shared -std=c++11"
    make -j$(($(nproc) - 1))
    make install

    popd
    rm -rf $COMPILATIONDIR
}


function installboost() {
    mkdir $COMPILATIONDIR
    pushd $COMPILATIONDIR

    BOOST_VERSION_UNDERSCORE="${BOOST_VERSION//\./_}"
    curl --silent --location --remote-name "https://boostorg.jfrog.io/artifactory/main/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION_UNDERSCORE}.tar.gz"
    tar -xzf "boost_${BOOST_VERSION_UNDERSCORE}.tar.gz"
    cd "boost_${BOOST_VERSION_UNDERSCORE}" 
    source scl_source enable devtoolset-8 
    ./bootstrap.sh --help
    ./bootstrap.sh --prefix=$MGHOME  --with-python=$(command -v python3)
    ./b2 install -j$(($(nproc) - 1))

    popd
    rm -rf $COMPILATIONDIR
}


function installMG() {
    pushd $MGHOME
    wget --quiet https://launchpad.net/mg5amcnlo/3.0/3.3.x/+download/MG5_aMC_v${MG_VERSION}.tar.gz 
    mkdir -p $MGHOME/MG5_aMC 
    tar -xzvf MG5_aMC_v${MG_VERSION}.tar.gz --strip=1 --directory=MG5_aMC
    rm MG5_aMC_v${MG_VERSION}.tar.gz

    echo "Installing MG5aMC_PY8_interface"
    mkdir $COMPILATIONDIR
    pushd $COMPILATIONDIR

    wget --quiet http://madgraph.phys.ucl.ac.be/Downloads/MG5aMC_PY8_interface/MG5aMC_PY8_interface_V${MG5aMC_PY8_INTERFACE_VERSION}.tar.gz
    mkdir -p MG5aMC_PY8_interface
    tar -xzvf MG5aMC_PY8_interface_V${MG5aMC_PY8_INTERFACE_VERSION}.tar.gz --directory=MG5aMC_PY8_interface
    cd MG5aMC_PY8_interface
    python compile.py $MGHOME --pythia8_makefile $(find $MGHOME -type d -name MG5_aMC)
    mkdir -p $MGHOME/MG5_aMC/HEPTools/MG5aMC_PY8_interface
    cp *.h $MGHOME/MG5_aMC/HEPTools/MG5aMC_PY8_interface/
    cp *_VERSION_ON_INSTALL $MGHOME/MG5_aMC/HEPTools/MG5aMC_PY8_interface/
    cp MG5aMC_PY8_interface $MGHOME/MG5_aMC/HEPTools/MG5aMC_PY8_interface/

    popd
    rm -rf $COMPILATIONDIR

    popd
}


function morestuff() {
    sed -i '/fastjet =/s/^# //g' $MGHOME/MG5_aMC/input/mg5_configuration.txt
    sed -i '/lhapdf_py3 =/s/^# //g' $MGHOME/MG5_aMC/input/mg5_configuration.txt
    sed -i 's|# pythia8_path.*|pythia8_path = $MGHOME|g' $MGHOME/MG5_aMC/input/mg5_configuration.txt
    sed -i '/mg5amc_py8_interface_path =/s/^# //g' $MGHOME/MG5_aMC/input/mg5_configuration.txt
    sed -i 's|# eps_viewer.*|eps_viewer = '$(command -v ghostscript)'|g' $MGHOME/MG5_aMC/input/mg5_configuration.txt
    sed -i 's|# fortran_compiler.*|fortran_compiler = '$(command -v gfortran)'|g' $MGHOME/MG5_aMC/input/mg5_configuration.txt


    #useradd --shell /bin/bash -m docker
    #cp /root/.bashrc /home/docker/ 
    #mkdir /home/docker/data 
    #chown -R --from=root docker /home/docker 
    #chown -R --from=root docker /usr/local/venv 
    #chown -R --from=503 docker /usr/local/venv/MG5_aMC


    python3 -m pip --no-cache-dir install --upgrade pip setuptools wheel
    python3 -m pip --no-cache-dir install six numpy readline
    sed -i 's|# f2py_compiler_py3.*|f2py_compiler_py3 = '$(command -v f2py)'|g' $MGHOME/MG5_aMC/input/mg5_configuration.txt
    echo "exit" | mg5_aMC
    echo "install ninja" | mg5_aMC
    echo "install collier" | mg5_aMC
    echo "generate p p > e+ e- aEW=2 aS=0 [QCD]; output test_nlo" | mg5_aMC
    rm -rf test_nlo
    rm -rf $(find $MGHOME -type d -name HEPToolsInstallers) 
    rm py.py
}


#installpython

# installHEPMC

#installfastjet

#installlhapdf

#installpythia

#installboost

#installMG

