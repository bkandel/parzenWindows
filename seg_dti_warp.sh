#!/bin/bash

KIRBY_PATH=${HOME}/Dropbox/MVSEG/dti_distance_project/kirby/subj_113
KIRBY_DT=$(ls ${KIRBY_PATH}/*dt*)
TEMPLATE_DIR=${HOME}/Dropbox/MVSEG/dti_distance_project/home/cbrun/TSA/atlas_construction/adult_template
TEMPLATE_FA=mean_diffeomorphic_initial6_fa.nii.gz
fa=fa.nii.gz 
FA_MASK=fa_mask.nii.gz 

export ANTSPATH=${ANTSPATH:="$HOME/ants-build/"}

# generate FA of Kirby subject
i=1
for dt in ${KIRBY_DT}; do
    ${ANTSPATH}ImageMath 3 kirby_fa_${i}.nii.gz TensorFA $dt
    ~/ANTS/Scripts/ants.sh 3  kirby_fa_${i}.nii.gz ${TEMPLATE_DIR}/${TEMPLATE_FA} atlas2kirby_${i} 30x30x30 &
    let i=i+1
done 
wait

# Warp atlases to Kirby subject space.
i=1
for dt in ${KIRBY_DT}; do
    for mask in atlas_masks/*; do
        ${ANTSPATH}WarpImageMultiTransform 3 $mask $(basename $mask .nii.gz)_warped_${i}.nii.gz -R kirby_fa_${i}.nii.gz atlas2kirby_${i}Warp.nii.gz atlas2kirby_${i}Affine.txt &
    done
    wait    
    newdir1=warped_masks_${i}
    newdir2=warped_masks_list_${i}
    if [ ! -d ${newdir1} ]; then 
        mkdir ${newdir1}
        #mkdir ${newdir2} used if we didn't generate a list of smoothed labels later
    fi 
    mv *binary_warped*${i}* ${newdir1}
    let i=i+1
done

if [ ! -d transforms ]; then
    mkdir transforms
fi 
mv atlas2kirby* transforms

i=1 
for DT in ${KIRBY_DT}; do
    ct=1
    for mask in warped_masks_${i}/*; do
        ${ANTSPATH}SmoothImage 3 $mask 0.5  warped_masks_${i}/tract_prob${ct}.nii.gz &
        let ct=$ct+1
    done
    let i=i+1
done
wait 

i=1
for DT in ${KIRBY_DT}; do 
    if [ ! -d kirby_${i}_imgs ]; then 
        mkdir kirby_${i}_imgs
    fi
    Out=kirby_${i}_imgs/out
    all_masks=$(ls warped_masks_list_${i}/*)
    num_tracts=$(ls warped_masks_list_${i}/* | wc -l)
    ${ANTSPATH}ImageMath 3 $fa TensorFA $DT 
    ${ANTSPATH}ThresholdImage 3 $fa ${FA_MASK} 0.21 9999
    for x in warped_masks_${i}/tract_prob*; do 
        ${ANTSPATH}ThresholdImage 3  $x  temp.nii.gz  0.25  999 ; # needs to be done sequentially
        ${ANTSPATH}ImageMath 3 ${FA_MASK} + ${FA_MASK} temp.nii.gz ; # i think substituting FA_MASK for "mask.nii.gz" as in Brian's code is fine
    done 
    ${ANTSPATH}ThresholdImage 3 ${FA_MASK} ${FA_MASK} 1 999
    IMGS=" -a v0.nii.gz -a v1.nii.gz  -a v2.nii.gz -a v3.nii.gz  -a v4.nii.gz -a v5.nii.gz "
    for x in 0 1 2 3 4 5 ; do   
        ${ANTSPATH}/ImageMath 3 v${x}.nii.gz ExtractVectorComponent $DT $x 
    done
    ${ANTSPATH}Atropos -d 3 -i PriorProbabilityImages[$num_tracts,warped_masks_${i}/tract_prob%d.nii.gz,0.5] -x $mask -o [${Out}_non.nii.gz,${Out}_oprob%02d.nii.gz] $IMGS -c [5,0]  -p Socrates[1] -m [0.2,1x1x1]  -k jointshapeandorientationprobability[2,32]  &
    for x in 0 1 2 3 4 5 ; do   
        ${ANTSPATH}ImageMath 3 v${x}.nii.gz ExtractVectorComponent $DT $x 
        ${ANTSPATH}MultiplyImages 3  v${x}.nii.gz 1.e5    v${x}.nii.gz # for mahalanobis
    done
    ${ANTSPATH}/Atropos -d 3 -i PriorProbabilityImages[$num_tracts,warped_masks_${i}/tract_prob%d.nii.gz,0.5] -x $mask -o [${Out}_mah.nii.gz,${Out}_oprob%02d.nii.gz] $IMGS -c [3,0]  -p Socrates[1] -m [0.2,1x1x1]  
    echo $exe ; $exe 
    for x in 0 1 2 3 4 5 ; do 
        rm v${x}.nii.gz
    done

    let i=${i}+1    
done
wait
  
  
