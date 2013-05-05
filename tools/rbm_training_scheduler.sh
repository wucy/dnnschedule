#!/bin/bash

BIN=/slfs2/src/TNet/trunk/src/TRbmCu
[ -r $BIN ] || { echo "$BIN does not exist"; exit 1; }

##############################
#check for obligatory parameters
echo RBM: ${RBM?$0: RBM not specified}
echo RBM_transf: ${RBM_transf?$0: RBM_transf not specified}
echo FRM_EXT: ${FRM_EXT?$0: FRM_EXT not specified}
echo SCP_TRAIN: ${SCP_TRAIN?$0: SCP_TRAIN not specified}

##############################
#define implicit configuration
echo LEARNRATE: ${LEARNRATE:=0.1}
echo LEARNRATE_LOW: ${LEARNRATE_LOW:=0.001}
echo MOMENTUM: ${MOMENTUM:=0.5}
echo MOMENTUM_HIGH: ${MOMENTUM_HIGH:=0.9}
echo WEIGHTCOST: ${WEIGHTCOST:=0.0002}
echo ITERS: ${ITERS:=10}
echo ITERS_HIGH: ${ITERS_HIGH:=20}
echo SAVEPOINTS: ${SAVEPOINTS:=5}

echo BUNCHSIZE: ${BUNCHSIZE:=128}
echo CACHESIZE: ${CACHESIZE:=32768}
echo RANDOMIZE: ${RANDOMIZE:=TRUE}



#do we have gaussian units? -> lower lrate, more iters
if [ 0 != $(grep gauss $RBM | wc -l | cut -d' ' -f 1) ]; then
  LEARNRATE=$LEARNRATE_LOW
  ITERS=$ITERS_HIGH
fi

#iterate
for iter in $(seq $ITERS); do
  echo '################################'
  echo "# ITER $iter/$ITERS $(date)" 
  echo '################################'
  $BIN -A  -D -V -T 5 \
    --FEATURETRANSFORM=$RBM_transf \
    -H $RBM \
    -S $SCP_TRAIN \
    --LEARNINGRATE=$LEARNRATE \
    --MOMENTUM=$MOMENTUM \
    --WEIGHTCOST=$WEIGHTCOST \
    --BUNCHSIZE=$BUNCHSIZE \
    --CACHESIZE=$CACHESIZE \
    --RANDOMIZE=$RANDOMIZE \
    --TARGETMMF=$RBM \
    --startFrmExt=$FRM_EXT \
    --endFrmExt=$FRM_EXT \
    ${CONF:+-C $CONF} || exit 1
  if [ $iter == 5 ]; then MOMENTUM=$MOMENTUM_HIGH; fi

  #save progress
  DIV=$((ITERS/SAVEPOINTS)); [ "$DIV" -eq "0" ] && DIV=1;
  if [[ $((iter % DIV)) == "0" ]]; then
    echo saving ${RBM}_iter$iter...
    cp $RBM ${RBM}_iter$iter
  fi
done

