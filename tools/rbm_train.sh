#!/bin/bash

########################################################
# SELECT TNET LOCATION
TNET_ROOT='/slfs2/src/TNet/trunk'

############################################
# CONFIG
TOPOLOGY=(429 2048 2048 2048 2048 2048)
RBM_UNIT_TYPES=(gauss bern bern bern bern bern)
#NEGBIAS=1

SCP_TRAIN='rbmtrain.scp'
FEATURE_TRANSFORM='global.transf'
FRM_EXT=5
#CONF=''

LEARNRATE=0.02
LEARNRATE_LOW=0.002
MOMENTUM=0.5
MOMENTUM_HIGH=0.9
WEIGHTCOST=0.0002
ITERS=15
ITERS_HIGH=30
SAVEPOINTS=5

BUNCHSIZE=256
CACHESIZE=81920
RANDOMIZE=TRUE

############################################

#create weight directory
[ -d weightsRBM ] || mkdir weightsRBM

#copy the feature transform
cp $FEATURE_TRANSFORM weightsRBM/tr
RBM_transf=weightsRBM/tr


#pretrain layers
for N in $(seq 0 $((${#TOPOLOGY[@]}-2))); do
  #initialize RBM
  python ./tools/gen_rbm_init.py \
   --dim=${TOPOLOGY[$N]}:${TOPOLOGY[$((N+1))]} \
   --gauss ${NEGBIAS:+ --negbias} \
   --vistype=${RBM_UNIT_TYPES[$N]} \
   --hidtype=${RBM_UNIT_TYPES[$((N+1))]} \
   > weightsRBM/L$N.init
  #make a copy for training 
  RBM=weightsRBM/L$N
  cp weightsRBM/L$N.init $RBM

  #train single RBM layer
  (
   source ./tools/rbm_training_scheduler.sh
  )
  
  #add RBM to feature transform
  {
   cat $RBM_transf 
   python ./tools/rbm2mlplayer.py $RBM -
  } >${RBM_transf}_L$N
  RBM_transf=${RBM_transf}_L$N
done
