#!/bin/bash

#ln -s ../preparedata/align
#ln -s ../preparedata/workdir/flists
#ln -s ../preparedata/workdir/mlfs

#cat align/train.failedsegs flists/rbmtrain-tjoiner5.scp | awk -F "=" 'NF==1{a[$1]=1;}NF==2{if(a[$1]!=1) print $0;}' > rbmtrain.scp
#cat align/train.failedsegs flists/bptrain_cv-tjoiner5.scp | awk -F "=" 'NF==1{a[$1]=1;}NF==2{if(a[$1]!=1) print $0;}' > train_cv.scp


# get dict
#mkdir -p dicts
#cat mlfs/ref.mlf | awk 'NF>=3{print $3;}' | sort -u > dicts/dict

# get state number
#ns=`cat align/statemap | awk '{print $NF;}' | sort -u | wc -l`

# initial mlp
#python ../tools/gen_mlp_init.py --dim=1024:$ns --gauss --negbias > 2048_${ns}.init



#for nn in tr_L0_L1_L2_L3
#do
#mkdir $nn
#cat ../rbmpretrain/weightsRBM/$nn | awk 'BEGIN{out=0;}$1=="<biasedlinearity>"{out=1;}{if(out==1) print $0;}' > $nn/tr_finetune
#cat $nn/tr_finetune 2048_${ns}.init > $nn/nnet_${nn}.init
#cd $nn
#ln -s ../tools
#ln -s ../../preparedata/workdir/mlfs/ref.mlf
#ln -s ../dicts/dict
#ln -s ../../plp_0_d_a.conf
#ln -s ../../rbmpretrain/global.transf
#ln -s ../train_cv.scp
#ln -s ../rbmtrain.scp
# need to submit to different machines
#qsub -cwd -l hostname=markov -o bp.${nn}.LOG -j y -S /bin/bash ./tools/tnet_train.sh nnet_${nn}.init
#cd ..
#done
