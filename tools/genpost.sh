#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: genpost.sh NN test-desc"
    exit
fi

NNET=$1
test=$2

if [ $test == "test" ]; then
    rawt=6242.34
elif [ $test == "dev" ]; then
    rawt=2026.09
elif [ $test == "test-0706" ]; then 
    rawt=1296.59
elif [ $test == "aiopnexmr_wrddev12oct_offline_v1-hyt" ]; then
    rawt=2037.03
elif [ $test == "ai_hcsnor_evl12oct_v1" ]; then
     rawt=5072.14
else
    echo "Unknown testset $test"
fi

echo $rawt

st=`date +%s`
echo "Start generating posteriors at $st"

/slfs2/src/TNet/trunk/src/TFeaCatCu -D -A -T 1 -C plp_0_d_a.conf \
 -S plpflists/${test}.scp \
 -H $NNET \
 -l data/$test \
 -y htk_post \
 --FEATURETRANSFORM='global.transf' \
 --GMMBYPASS=true \
 --START-FRM-EXT=5 \
 --END-FRM-EXT=5 
end=`date +%s`
echo "Ending at $end"

# get raw time
echo 0 | awk -v s=$st -v e=$end -v r=$rawt -v t=$test '{printf "%s\t RawTime: %.2f\t RunTime %.2f\t RTF: %.2f\n",t,r,e-s,(e-s)/r;}'

