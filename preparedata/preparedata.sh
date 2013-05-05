#!/bin/bash

source ../config.sh

#mkdir $out_dir

#ln -s ../tools
#ln -s ../../ams/lib


# 1. force alginment

#ln -s ~/workdir/slfs3/baseline_qyzj/ams/S2_hlda_varmix/xforms

#ls lib/flists/train_*.scp > scplist
#nscp=`cat scplist | wc -l`
#qsub -l hostname=markov -cwd -o alignsub.LOG -e alignsub.LOG -t 1-$nscp -S /bin/bash /slfs2/src/tools/run-array-job.sh scplist ./tools/align-state.sh HTE.align SET
#./tools/align-state.sh HTE.align scplist 


#for scp in `cat scplist`;do
#{
#	./tools/align-state.sh HTE.align ${scp}
#}&
#done
#wait

#echo "force align finished."


#cat align/*.LOG | egrep -B 5 'No token' | grep Aligning | awk '{printf "%s\n",$NF}' > align/train.failedsegs
#cat align/*_*.mlf > align/train.align.mlf


# get statemap
#ln -s ~/workdir/slfs3/baseline_qyzj/ams/S2_hlda_varmix/hmm1210/MMF align/MMF
#HHEd -H align/MMF -w mmf.tmp /dev/null ./lib/mlists/tri.xwrd.cluster.list
#cat mmf.tmp | sed 's="==g' | awk '$1=="~h"{hmm=$2;}$1=="<STATE>"{sid=$2;getline;printf "%s[%d]\t%s\n",hmm,sid,$2;}' > align/statemap

# get compact mlf


#mkdir $out_dir/mlfs
#cat lib/flists/train*.scp | grep -v -f align/train.failedsegs  | sed 's=\.plp.*=.rec=g' > tmplist
#HLEd -C lib/cfgs/hled.cfg -I align/train.align.mlf -l '*' -i $out_dir/mlfs/reftmp.mlf -S tmplist /dev/null
#cat align/statemap $out_dir/mlfs/reftmp.mlf | awk 'NF==2{a[$1]=$2;}NF>=4{printf "%s %s %s\n",$1,$2,a[$3];}NF!=2 && NF<4{print $0;}' > $out_dir/mlfs/ref.mlf




# 2. get train and test scp
mkdir -p $out_dir/features
mkdir -p $out_dir/flists

# randomly select about 20% data as the cv
#rm -f workdir/flists/bptrain_cv.scp workdir/flists/rbmtrain.scp
#cat lib/flists/train.scp | sort | awk '{printf "%f\t%s\n",rand(),$0;}' | sort +0 -1g | awk 'BEGIN{fn1="workdir/flists/rbmtrain.scp";fn2="workdir/flists/bptrain_cv.scp";}{if($1>0.855) print $2 >> fn2;else print $2 >> fn1;}'

# 3. join the features of the training set
FRM_EXT=5
#for scp in rbmtrain bptrain_cv
#do
#mkdir -p $out_dir/features/${scp}-tjoiner${FRM_EXT}
#$TNetbin/TJoiner -A -D -V -T 021 -S $out_dir/flists/${scp}.scp -C ../plp_0_d_a.conf -l `pwd`/$out_dir/features/${scp}-tjoiner${FRM_EXT} --OUTPUT-SCRIPT=$out_dir/flists/${scp}-tjoiner${FRM_EXT}.scp --START-FRM-EXT=$FRM_EXT --END-FRM-EXT=$FRM_EXT | tee TJoiner.${scp}.LOG
#done

# 4. global normalization
# generate identity transform
#mkdir norm
#./tools/genidenty.sh norm/identity.trans
#$TNetbin/TNorm -D -A -T 1 -S $out_dir/flists/rbmtrain-tjoiner5.scp -H norm/identity.trans --TARGET-MMF=norm/global.norm --START-FRM-EXT=$FRM_EXT --END-FRM-EXT=$FRM_EXT | tee TNorm.LOG
#cat norm/identity.trans norm/global.norm > norm/global.transf

# now can go to rbm train
