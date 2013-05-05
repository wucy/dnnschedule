#!/bin/bash

if [ $# -ne 3 ];then
    echo "Usage: gen_HTK_gmmbypass.sh inputMMF.txt stateprior outputGmmBypass"
    exit
fi

MMF=$1
stePrior=$2
outMMF=$3

# split MMF 
cat $MMF | awk '$1=="~v"{getline;getline;getline;}$1=="~s"{out=0;}{if(out==1) print $0;}$0~/NULLD/{out=1;}' > MMF.trans
cat $MMF | awk '$1=="~h"{out=1;}{if(out==1) print $0;}' > MMF.hmm

# get vector size: number of clustered states
cat $MMF | grep ~s | sed 's="==g' | awk '{print $2;}' | sort -u > statelist  # this should be consistent with phonelist
cat $stePrior | awk '{print $1;}' | sort > statelist2
diff statelist statelist2 > statelist.diff

if [ -s statelist.diff ]; then
    echo "State prior is not consistent with HMM"
    exit 1
fi
vecsize=`cat $stePrior | wc -l`

echo "~o <VecSize> $vecsize <USER>" > $outMMF
cat MMF.trans >> $outMMF

# set GConst=2*log P(s) so that p(O|s) takes into account P(s)
{
    for((ste=1;ste<=$vecsize;ste++));
      do 
      steid=`sed -n "$ste p" $stePrior | awk '{print $1;}'`
      gconst=`sed -n "$ste p" $stePrior | awk '{print $2;}'`
      echo 0 | awk -v vec=$vecsize -v curline=$ste -v id=$steid -v g=$gconst '{printf "~s \"%s\"\n",id;printf "\t<Mean> %d\n\t\t",vec;for(i=1;i<=vec;i++) printf "0.0 ";printf "\n\t<Variance> %d\n\t",vec;for(i=1;i<curline;i++) printf "1e30 ";printf "1.0 ";for(i=curline+1;i<=vec;i++) printf "1e30 ";printf "\n\t<GConst> %f\n",g;}'
    done
} >> $outMMF

cat MMF.hmm >> $outMMF

echo "HTK_GmmByPass: vecsize: $vecsize "
