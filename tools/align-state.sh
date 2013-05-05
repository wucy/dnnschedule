#!/bin/tcsh

if ( $#argv != 2 ) then
    echo "Usage: align-state.sh HTE scp"
    exit
endif

source $1

set scp = $2
set scpbase = `basename $scp`
set mlf = ${scpbase}.align.mlf
set log = $outdir/align-state.${scpbase}.LOG

echo "BEGIN ${scp}"

mkdir -p $outdir

/slfs2/src/bin/HVite -A -D -T 1 -a -f -i $outdir/$mlf -H $model -y rec -C $config -t 500.0 -I $wordmlf -b sil -S $scp $dict $mlist > $log

echo "FINISH ${scp}"

