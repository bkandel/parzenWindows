#!/bin/bash
for file in KKI2009-30-DWI_left*
do
echo "Processing file $file" 
./seg_dti_manual_init_atroposMin.sh KKI2009-30-DWI_dt.nii Tensor out $file 2
FILE_NAME=$(basename $file .nii)
mkdir $FILE_NAME
mv hist* $FILE_NAME
done
