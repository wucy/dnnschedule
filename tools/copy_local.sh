#!/bin/bash


##################################################
# check that the parameters are set!
#
if [ ! $SCP_CV ]; then
  echo SCP_CV must be defined
  exit 1
fi
if [ ! $SCP_TRAIN ]; then
  echo SCP_TRAIN must be defined
  exit 1
fi

if [ ! -e $SCP_TRAIN ]; then
  if [ ! $LIST ]; then
    echo LIST must be defined
    exit 1
  fi
  if [ ! $train_start ]; then
    echo train_start must be defined
    exit 1
  fi
  if [ ! $train_count ]; then
    echo train_count must be defined
    exit 1
  fi
  if [ ! $cv_start ]; then
    echo cv_start must be defined
    exit 1
  fi
  if [ ! $cv_count ]; then
    echo cv_count must be defined
    exit 1
  fi
fi



if [ ! $SED_ARG_CREATE_LOCAL ]; then
  echo SED_ARG_CREATE_LOCAL must be defined
  exit 1
fi




########################################################
# create dir for lists
if [ ! -e lists ]; then
  mkdir 'lists'
fi
SCP_CV_LOCAL=lists/${SCP_CV##*/}_local
SCP_TRAIN_LOCAL=lists/${SCP_TRAIN##*/}_local


########################################################
# create lists (don't overwrite external lists!)
# remove directory from logical filenames
if [[ "$LIST" != "" && "$SCP_TRAIN" == "lists/train.scp" && "$SCP_CV" == "lists/cv.scp" ]]; then
  echo splitting list: $LIST 
  cat $LIST | head -n $((train_start+train_count)) | tail -n $train_count | sed 's|.*/\([^/]*\)=|\1=|' > $SCP_TRAIN
  cat $LIST | head -n $((cv_start+cv_count)) | tail -n $cv_count | sed 's|.*/\([^/]*\)=|\1=|' > $SCP_CV
else
  echo using predefined lists:
  echo $SCP_TRAIN 
  echo $SCP_CV
fi


########################################################
# test if we're cheating with train/dev data
cheating=$(join $SCP_CV $SCP_TRAIN | wc -l)
if [ $cheating -gt 0 ]; then
  join $SCP_CV $SCP_TRAIN >&2
  echo trainset and devset must be disjoint sets!!!! >&2
  exit 1
fi

len_train=$(cat $SCP_TRAIN | wc -l)
len_cv=$(cat $SCP_CV | wc -l)
echo
echo trainset has $len_train utterances "($SCP_TRAIN)"
echo devset has $len_cv utterances "($SCP_CV)"
echo
if [[ $len_train == 0 || $len_cv == 0 ]] ; then
  echo Error, the set was empty!
  exit 1
fi


if [ "$COPY_LOCAL" != "1" ]; then
  SCP_TRAIN_LOCAL=$SCP_TRAIN
  SCP_CV_LOCAL=$SCP_CV
else

########################################################
# create local script files
cat $SCP_TRAIN | sed $SED_ARG_CREATE_LOCAL > $SCP_TRAIN_LOCAL
cat $SCP_CV | sed $SED_ARG_CREATE_LOCAL > $SCP_CV_LOCAL
########################################################
#copy data locally
echo 'copying data locally'
date

filelist=$(cat $SCP_CV $SCP_TRAIN | sed -e 's|.*=||g' -e 's|\[.*||g' |sort|uniq)
for file in $filelist; do
  #create local dir
  dir_local=$(echo $file | sed $SED_ARG_CREATE_LOCAL | sed 's|/[^/]*$||')
  if [ ! -e $dir_local ]; then 
    mkdir -p $dir_local
  fi
  #copy file if not already present
  localfile=$dir_local/${file##*/}
  if [ ! -e $localfile ]; then
    cp $file $localfile
  fi
  #check size of files
  size_remote=$(stat -c%s "$file")
  size_local=$(stat -c%s "$localfile")
  if [ ${size_remote:-0} != ${size_local:-0} ]; then
    cp $file $dir_local
  fi
  #finally check if the file was copied correctly
  size_local=$(stat -c%s "$localfile")
  if [ ${size_remote:-0} != ${size_local:-0} ]; then
    echo "error cannot copy $file -> $localfile"
    exit 1
  fi
done


#test one file if the whole thing was properly copied 
local_file=$(cat $SCP_TRAIN_LOCAL | head -n 1 | sed -e 's|.*=||g' -e 's|\[.*||')
if [ ! -e $local_file ]; then
  echo data were not correctly copied to local: 
  echo cannot find $local_file
  exit 1
fi

echo 'copy finished'
date

fi #COPY_LOCAL=1

