#!/bin/bash
if [ $# -lt 5 ] ; then 
echo usage
echo $0 DT.nii.gz SegType OutPrefix InitializationImages.nii.gz N-Classes 
echo SegType in \{ RGB, Tensor \}
exit
fi 
if [ ${#ANTSPATH} -le 3 ] ; then 
  echo we guess at your ants path 
  export ANTSPATH=${ANTSPATH:="$HOME/ANTS-test/ants-build-test/"} # EDIT THIS
  echo we guess that your antspath is $ANTSPATH 
fi 
if [ ! -s ${ANTSPATH}/ANTS ] ; then 
  echo we cant find the ANTS program -- does not seem to exist.  please \(re\)define \$ANTSPATH in your environment.
  exit
fi 


DT=$1
SegType=$2
Out=$3
Init=$4
NC=$5
if [ ! -s $DT ] ; then 
 echo the DT image , $DT , does not exist. please find a valid one to use or fix the file/path name.
 exit 
fi 
if [ ! -s $Init ] ; then 
 echo the manual initialization image , $Init , does not exist. please create a manual initialization with ITK-Snap. 
 exit 
fi 
fa=fa.nii.gz 
mask=mask.nii.gz 
${ANTSPATH}/ImageMath 3 $fa TensorFA $DT 
${ANTSPATH}/ThresholdImage 3 $fa $mask 0.15 9999
${ANTSPATH}/ImageMath 3 $mask GetLargestComponent $mask
if [ $SegType == "RGB" ] ; then 
  ${ANTSPATH}/ImageMath 3 rgb.nii.gz TensorColor $DT
  ${ANTSPATH}/ImageMath 3 r.nii.gz ExtractVectorComponent rgb.nii.gz 0
  ${ANTSPATH}/ImageMath 3 g.nii.gz ExtractVectorComponent rgb.nii.gz 1
  ${ANTSPATH}/ImageMath 3 b.nii.gz ExtractVectorComponent rgb.nii.gz 2
  ${ANTSPATH}/Atropos -d 3 -i PriorLabelImage[${NC},${Init},0.] -x $mask -o ${Out}.nii.gz -a r.nii.gz -a g.nii.gz -a b.nii.gz -c [5,0]  -p Plato[0] -m [0.4,1x1x1] # -k HistogramParzenWindows[1,8]
  rm r.nii.gz g.nii.gz b.nii.gz rgb.nii.gz 
elif [ $SegType == "Tensor" ] ; then 
  for x in 0 1 2 3 4 5 ; do   
    ${ANTSPATH}/ImageMath 3 v${x}.nii.gz ExtractVectorComponent $DT $x 
  done
  IMGS=" -a v0.nii.gz -a v1.nii.gz  -a v2.nii.gz -a v3.nii.gz  -a v4.nii.gz -a v5.nii.gz "
  ${ANTSPATH}/AtroposMin -d 3 -i PriorLabelImage[${NC},${Init},0.0] -x $mask -o ${Out}.nii.gz $IMGS -c [4,0]  -p Plato[0] -m [0.4,1x1x1]  -k jointshapeandorientationprobability[1,16]
  for x in 0 1 2 3 4 5 ; do 
   rm v${x}.nii.gz
  done
else 
  echo cannot find SegType $SegType , try RGB or Tensor 
fi
rm mask.nii.gz fa.nii.gz

