source scl_source enable devtoolset-8

export MGHOME=./MadGraph.3.3.2
export PYTHON39PATH=$MGHOME/python39


export PATH=$MGHOME/MG5_aMC/bin:$MGHOME/bin:$PATH

export PATH=$PYTHON39PATH/bin:$PATH
export LD_LIBRARY_PATH=$PYTHON39PATH/lib:$MGHOME/lib:$LD_LIBRARY_PATH
export PYTHONPATH=$MGHOME/MG5_aMC:$MGHOME/lib


source $MGHOME/python39/lib/python3.9/venv/scripts/common/activate
 
