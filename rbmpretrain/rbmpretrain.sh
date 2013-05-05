
ln -s ../preparedata/norm/global.transf
ln -s ../preparedata/workdir/flists/rbmtrain-tjoiner5.scp rbmtrain.scp
ln -s ../tools/

qsub -cwd -l hostname=markov -o rbm_train.LOG -j y -S /bin/bash ./rbm_train.sh

