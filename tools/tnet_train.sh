#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: tnet_train.sh InitNN"
    exit
fi

########################################################
# SELECT TNET LOCATION
TNET_ROOT='/home/slhome/cyw56/tools/tnet/trunk'

########################################################
# FEATURES CONFIG 
#

# or set existing SCP_CV SCP_TRAIN lists
SCP_CV='train_cv.scp'
SCP_TRAIN='rbmtrain.scp'

# FEATURE NORMALIZATION
STK_CONF='plp_0_d_a.conf'


########################################################
# THIS IS THE SED ARGUMENT THAT WILL CHANGE DISTANT 
# FILE LOCATION TO LOCAL FILE LOCATION!!!!!
COPY_LOCAL=1
SED_ARG_CREATE_LOCAL='s|mnt/scratch05|tmp|g'
###################

# OTHER CONFIG
MLF_CV='ref.mlf'
MLF_TRAIN='ref.mlf'
PHONELIST='dict'
FEATURE_TRANSFORM='global.transf'
FRM_EXT=5

LEARNRATE=0.08
MOMENTUM=0.9 #only with GPU
WEIGHTCOST=1e-6

BUNCHSIZE=256
CACHESIZE=81920
RANDOMIZE=TRUE
#TRACE=5 #01..progress 02..dots_on_bunch 04..profile
#TNET_FLAGS=" " # -A..cmdline -D..config -V verbose
#CONFUSIONMODE=max #no,max,soft,dmax,dsoft [in CPU TNet only]

MAX_ITER=20
MIN_ITER=1
KEEP_LRATE_ITER=0
END_HALVING_INC=0.1
START_HALVING_INC=0.5
HALVING_FACTOR=0.6

# END OF CONFIG
########################################################




########################################################
#copy data to local
#(or just split the lists if COPY_LOCAL!=1)
source ./tools/copy_local.sh

########################################################
#clean the data upon exit
# trap "source ./tools/delete_local.sh" EXIT


########################################################
#run the TNet training

#inintialize the network
NN_INIT=$1
#'nnet_429_1024_1024_1024_2077.init'
if [ ! -e $NN_INIT ]; then
 # {
    # more commands here...
  #  python ./tools/gen_mlp_init.py --dim=429:1024:1024:1024:2077 --gauss --negbias
    # more commands here...
 # } > $NN_INIT 
  echo "NN_Init is not specified "
  exit
else
  echo using preinitialized network $NN_INIT
fi 


#run the training
source ./tools/training_scheduler.sh


