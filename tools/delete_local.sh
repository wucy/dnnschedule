#!/bin/bash

#check the variables
if [ ! $SCP_TRAIN_LOCAL ]; then
  echo SCP_TRAIN_LOCAL must be set!
  exit 1
fi
if [ ! $SCP_CV_LOCAL ]; then
  echo SCP_CV_LOCAL must be set!
  exit 1
fi




#remove the data from local when inside a SGE job
if [ "$COPY_LOCAL" == "1" ]; then
  if [ $SGE_O_WORKDIR ]; then
    echo 'deleting the data from local'
    filelist=$(cat $SCP_CV_LOCAL $SCP_TRAIN_LOCAL | sed -e 's|.*=||g' -e 's|\[.*||g' |sort|uniq)
    echo "${filelist:0:500}..." | tr ' ' '\n'
    for file in $filelist; do
      if [ "${file:0:5}" == "/tmp/" ]; then
        rm $file
        if [ $? != 0 ]; then echo "Cannot remove $file" >&2; fi
      else
        BAD_SED_ARG_CREATE_LOCAL=1
        echo "Warning, local file not in /tmp/, file not deleted: $file"
      fi
    done
    if [ "$BAD_SED_ARG_CREATE_LOCAL" == "1" ]; then
      echo "Error, wrong SED_ARG_CREATE_LOCAL '$SED_ARG_CREATE_LOCAL'" >&2
      echo "the features were not locally copied" >&2
    fi
  fi
fi
