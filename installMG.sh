# ------------------------------- #
# Script to install MG and LHAPDF #
# ------------------------------- #

# For printing messages
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Some paths
MGPATH=$PWD/MG5_aMC_v3_5_3/

function install_mg() {
    # Function to get MG342
    echo -e "$GREEN >> Installing MG $NC" 
    wget https://launchpad.net/mg5amcnlo/3.0/3.5.x/+download/MG5_aMC_v3.5.6.tar.gz -O mg5.tar.gz 
    tar xzf mg5.tar.gz 

}

install_mg
