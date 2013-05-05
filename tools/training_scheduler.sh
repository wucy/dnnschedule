#!/bin/bash

#threads were not specified, assume using CUDA
if [[ ! $THREADS ]]; then
  CUDA=1
fi
TNet=$TNET_ROOT/src/TNet${CUDA:+Cu}
echo
echo This script: $0
echo
echo TNet: $TNet

##############################
#check for obligatory parameters
echo NN_INIT: ${NN_INIT?$0: NN_INIT not specified}
echo MLF_CV: ${MLF_CV?$0: MLF_CV not specified}
echo MLF_TRAIN: ${MLF_TRAIN?$0: MLF_TRAIN not specified}
echo SCP_CV_LOCAL: ${SCP_CV_LOCAL?$0: SCP_CV_LOCAL not specified}
echo SCP_TRAIN_LOCAL: ${SCP_TRAIN_LOCAL?SCP_TRAIN_LOCAL not specified}
echo LEARNRATE: ${LEARNRATE?$0: LEARNRATE not specified}

##############################
#define implicit configuration
echo BUNCHSIZE: ${BUNCHSIZE:=512}
echo CACHESIZE: ${CACHESIZE:=16384}
echo RANDOMIZE: ${RANDOMIZE:=TRUE}
echo TRACE: ${TRACE:=5}
echo TNET_FLAGS: ${TNET_FLAGS:=-A -D -V}

echo MAX_ITER: ${MAX_ITER:=20}
echo MIN_ITER: ${MIN_ITER:=1}
echo KEEP_LRATE_ITER: ${KEEP_LRATE_ITER:=0}
echo END_HALVING_INC: ${END_HALVING_INC:=0.1}
echo START_HALVING_INC: ${START_HALVING_INC:=0.5}
echo HALVING_FACTOR: ${HALVING_FACTOR:=0.5}



#runs the training commad, parses the accuracy
function run_tnet_parse_accu {
  local cmd=$1;
  echo %%%%%%
  echo $cmd
  echo %%%%%%
  local logfile=$(mktemp);
  $cmd | tee $logfile | sed 's|^|  |'
  #parse the logfile to get accuracy: 
  ACCU=$(cat $logfile | grep 'Xent:' | tail -n 1 | sed 's|.*\[\(.*\)%\].*|\1|')
  rm $logfile
  if [[ $ACCU == "" ]]; then
    echo "Error, No accuracy returned, terminating..."
    exit 1
  fi
}


if [ ! -d weights ]; then
  mkdir weights
fi

nnet_base=weights/$(basename $NN_INIT .init)

echo "########################################################"
echo "# INITIAL CROSSVAL, $(date)"
echo "########################################################"

cmd="$TNet $TNET_FLAGS -T $TRACE \
 -H $NN_INIT \
 -I $MLF_CV \
 -L '*/' -X lab \
 -S $SCP_CV_LOCAL \
 --BUNCHSIZE=$BUNCHSIZE \
 --CACHESIZE=$CACHESIZE \
 --RANDOMIZE=FALSE \
 --CROSSVALIDATE=TRUE \
 --OUTPUTLABELMAP=$PHONELIST \
 --STARTFRMEXT=$FRM_EXT \
 --ENDFRMEXT=$FRM_EXT \
 ${FEATURE_TRANSFORM:+--FEATURETRANSFORM=$FEATURE_TRANSFORM} \
 ${STK_CONF:+-C $STK_CONF} \
 ${THREADS:+--THREADS=$THREADS} \
 ${CONFUSIONMODE:+--CONFUSIONMODE=$CONFUSIONMODE} \
 "

run_tnet_parse_accu "$cmd"
accu_best=$ACCU
nnet_best=$NN_INIT
echo "Initial CV accuracy: $ACCU"\


lrate=$LEARNRATE
if [ $THREADS ]; then #divide lrate so it is 
  lrate=$(awk 'BEGIN{print('$lrate'/'$BUNCHSIZE');}')
fi

iter=0
do_halving=0
for iter in $(seq -w $MAX_ITER); do

  echo "########################################################"
  echo "# ITERATION:$iter, $(date)"
  echo "########################################################"
  nnet_next=${nnet_base}_iter$iter
  #run epoch
  cmd="$TNet $TNET_FLAGS -T $TRACE \
   -H $nnet_best \
   -I $MLF_TRAIN \
   -L '*/' -X lab \
   -S $SCP_TRAIN_LOCAL \
   --LEARNINGRATE=$lrate \
   ${LEARNRATEFACTORS:+--LEARNRATEFACTORS=$LEARNRATEFACTORS} \
   ${MOMENTUM:+--MOMENTUM=$MOMENTUM} \
   ${WEIGHTCOST:+--WEIGHTCOST=$WEIGHTCOST} \
   --BUNCHSIZE=$BUNCHSIZE \
   --CACHESIZE=$CACHESIZE \
   --RANDOMIZE=$RANDOMIZE \
   --OUTPUTLABELMAP=$PHONELIST \
   --TARGETMMF=$nnet_next \
   --STARTFRMEXT=$FRM_EXT \
   --ENDFRMEXT=$FRM_EXT \
   ${FEATURE_TRANSFORM:+--FEATURETRANSFORM=$FEATURE_TRANSFORM} \
   ${STK_CONF:+-C $STK_CONF} \
   ${THREADS:+--THREADS=$THREADS} \
   ${CONFUSIONMODE:+--CONFUSIONMODE=$CONFUSIONMODE} \
   "

  run_tnet_parse_accu "$cmd"
  accu_train=$ACCU
  echo "TR accuracy:  $ACCU iter: $iter learnrate: $lrate"\
   ${MOMENTUM:+" momentum: $MOMENTUM"}\
   ${WEIGHTCOST:+" weightcost: $WEIGHTCOST"}

  echo "########################################################"
  echo "# CROSSVAL:$iter, $(date)"
  echo "########################################################"

  cmd="$TNet $TNET_FLAGS -T $TRACE \
   -H $nnet_next \
   -I $MLF_CV \
   -L '*/' -X lab \
   -S $SCP_CV_LOCAL \
   --BUNCHSIZE=$BUNCHSIZE \
   --CACHESIZE=$CACHESIZE \
   --RANDOMIZE=FALSE \
   --CROSSVALIDATE=TRUE \
   --OUTPUTLABELMAP=$PHONELIST \
   --STARTFRMEXT=$FRM_EXT \
   --ENDFRMEXT=$FRM_EXT \
   ${FEATURE_TRANSFORM:+--FEATURETRANSFORM=$FEATURE_TRANSFORM} \
   ${STK_CONF:+-C $STK_CONF} \
   ${THREADS:+--THREADS=$THREADS} \
   ${CONFUSIONMODE:+--CONFUSIONMODE=$CONFUSIONMODE} \
   "

  run_tnet_parse_accu "$cmd"
  accu_cv=$ACCU
  echo "CV accuracy: $ACCU iter: $iter learnrate: $lrate"\
   ${MOMENTUM:+" momentum: $MOMENTUM"}\
   ${WEIGHTCOST:+" weightcost: $WEIGHTCOST"}

  nnet_next_accu=${nnet_next}_lr$(printf '%.5g' $lrate)_tr$(printf '%.5g' $accu_train)_cv$(printf '%.5g' $accu_cv)
  mv $nnet_next $nnet_next_accu

  # always accept the weights when fixed lrate by keep_lrate_iter
  if [[ ${iter##0} -lt $KEEP_LRATE_ITER ]]; then
    echo 'accepting weights (keep_lrate_iter)'
    nnet_best=$nnet_next_accu
    accu_prev=$accu_best
    accu_best=$accu_cv
    continue
  fi

  #revert the parameters or keep them
  if [[ 1 == $(awk 'BEGIN{print('$accu_cv'<'$accu_best')}') ]]; then
    echo 'reverting the weights' " $accu_cv < $accu_best"
    accu_prev=$accu_best
    mv $nnet_next_accu ${nnet_next_accu}_rejected
  else
    echo 'accepting weights'
    nnet_best=$nnet_next_accu
    accu_prev=$accu_best
    accu_best=$accu_cv
  fi

  # end training if halving already and not improving much
  if [[ $do_halving == 1 && 1 == $(awk 'BEGIN{print('$accu_best'<'$accu_prev'+'$END_HALVING_INC')}') && ${iter##0} -gt $MIN_ITER ]]; then
    break;
  fi


  # start halving when not improving much
  if [[ 1 == $(awk 'BEGIN{print('$accu_cv'<'$accu_prev'+'$START_HALVING_INC')}') ]]; then
    do_halving=1
  fi

  if [[ $do_halving == 1 ]]; then
    lrate=$(awk 'BEGIN{print('$lrate'*'$HALVING_FACTOR')}')
    echo lrate=$lrate
  fi

done

#copy-out the best network
if [ $iter -gt 0 ]; then
  cp $nnet_best ${nnet_base}_final_iters${iter}_tr$(printf '%.5g' $accu_train)_cv$(printf '%.5g' $accu_best)
fi

echo "########################################################"
echo "# END OF TRAINING, $(date)"
echo "########################################################"
