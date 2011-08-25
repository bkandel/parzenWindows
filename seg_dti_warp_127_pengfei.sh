#!/bin/bash

KIRBY_PATH=${HOME}/code/dti_distance_data/kirby/subj_127
KIRBY_DT=$(ls ${KIRBY_PATH}/*dt*)
TEMPLATE_DIR=${HOME}/code/dti_distance_data/home/cbrun/TSA/atlas_construction/adult_template
TEMPLATE_FA=mean_diffeomorphic_initial6_fa.nii.gz
fa=fa.nii.gz
FA_MASK=fa_mask.nii.gz 

export ANTSPATH=${ANTSPATH:="$HOME/ants-build/"}

 #generate FA of Kirby subject
i=1
for dt in ${KIRBY_DT}; do
    ${ANTSPATH}ImageMath 3 kirby_fa_${i}.nii.gz TensorFA $dt
    ~/ANTS/Scripts/ants.sh 3  kirby_fa_${i}.nii.gz ${TEMPLATE_DIR}/${TEMPLATE_FA} atlas2kirby_${i} 30x30x30 &
    let i=i+1
done 
wait

#Warp atlases to Kirby subject space.
i=1
for dt in ${KIRBY_DT}; do
    for mask in atlas_masks/*; do
        ${ANTSPATH}WarpImageMultiTransform 3 $mask $(basename $mask .nii.gz)_warped_${i}.nii.gz -R kirby_fa_${i}.nii.gz atlas2kirby_${i}Warp.nii.gz atlas2kirby_${i}Affine.txt &
    done
    wait    
    #newdir1=warped_masks_${i}
    #newdir2=warped_masks_list_${i}
    #if [ ! -d ${newdir1} ]; then 
        #mkdir ${newdir1}
        ##mkdir ${newdir2} used if we didn't generate a list of smoothed labels later
    #fi 
    #mv *binary_warped*${i}* ${newdir1}
    let i=${i}+1
done

if [ ! -d transforms ]; then
    mkdir transforms
fi 
mv atlas2kirby* transforms

i=1 
for DT in ${KIRBY_DT}; do
    ct=1
    for mask in *binary_warped_${i}*; do
        ${ANTSPATH}ThresholdImage 3 $mask tract_prob_subjt_${i}_${ct}.nii.gz 0.3 1
        ${ANTSPATH}SmoothImage 3 tract_prob_subjt_${i}_${ct}.nii.gz 0.5 tract_prob_subj_${i}_${ct}.nii.gz &
        let ct=$ct+1
    done
    let i=${i}+1
done
wait 

i=1
for DT in ${KIRBY_DT}; do 
    if [ ! -d kirby_${i}_imgs ]; then 
        mkdir kirby_${i}_imgs
    fi
    Out=kirby_${i}_imgs/out
    all_masks=$(ls tract_prob_subj_${i}*)
    num_tracts=$(ls tract_prob_subj_${i}* | wc -l)
    ${ANTSPATH}ImageMath 3 $fa TensorFA $DT 
    ${ANTSPATH}ThresholdImage 3 $fa ${FA_MASK} 0.25 9999
    ${ANTSPATH}ImageMath 3 ${FA_MASK} GetLargestComponent ${FA_MASK}
    ${ANTSPATH}MultiplyImages 3 ${FA_MASK} 0 ${FA_MASK}
    for x in tract_prob_subj_${i}*; do 
        ${ANTSPATH}ThresholdImage 3  $x  temp.nii.gz  0.25  999 ; # needs to be done sequentially
        ${ANTSPATH}ImageMath 3 ${FA_MASK} + ${FA_MASK} temp.nii.gz ; # i think substituting FA_MASK for "mask.nii.gz" as in Brian's code is fine
    done 
    ${ANTSPATH}ThresholdImage 3 ${FA_MASK} ${FA_MASK} 1 999
    IMGS=" -a v0.nii.gz -a v1.nii.gz  -a v2.nii.gz -a v3.nii.gz  -a v4.nii.gz -a v5.nii.gz "
    for x in 0 1 2 3 4 5 ; do   
        ${ANTSPATH}ImageMath 3 v${x}.nii.gz ExtractVectorComponent $DT $x 
    done
    ${ANTSPATH}Atropos -d 3 -i PriorProbabilityImages[$num_tracts,tract_prob_subj_${i}_%d.nii.gz,0.5] -x ${FA_MASK} -o [${Out}_non.nii.gz,${Out}_non_oprob%02d.nii.gz] $IMGS -c [5,0]  -p Socrates[1] -m [0.2,1x1x1]  -k jointshapeandorientationprobability[2,20]  
    for x in 0 1 2 3 4 5 ; do   
        ${ANTSPATH}ImageMath 3 v${x}.nii.gz ExtractVectorComponent $DT $x 
        ${ANTSPATH}MultiplyImages 3  v${x}.nii.gz 1.e5    v${x}.nii.gz # for mahalanobis
    done
    ${ANTSPATH}Atropos -d 3 -i PriorProbabilityImages[$num_tracts,tract_prob_subj_${i}_%d.nii.gz,0.5] -x ${FA_MASK} -o [${Out}_mah.nii.gz,${Out}_mah_oprob%02d.nii.gz] $IMGS -c [3,0]  -p Socrates[1] -m [0.2,1x1x1]  
    echo $exe ; $exe 
    for x in 0 1 2 3 4 5 ; do 
        rm v${x}.nii.gz
    done

    let i=${i}+1    
done
wait
  
  
~/ANTS/Scripts/antsaffine.sh 3 kirby_fa_1.nii.gz kirby_fa_2.nii.gz kirby2tokirby1affine
for i in 01 02 03 04 05 06 07 08 09 10; do
    ${ANTSPATH}WarpImageMultiTransform 3 kirby_2_imgs/out_mah_oprob${i}.nii.gz kirby_2_imgs/out_mah_oprob${i}_warped.nii.gz -R kirby_fa_1.nii.gz kirby2tokirby1affinedeformed.nii.gz kirby2tokirby1affineAffine.txt 
    ${ANTSPATH}ThresholdImage 3  kirby_2_imgs/out_mah_oprob${i}_warped.nii.gz kirby_2_imgs/out_mah_oprob${i}_warped_thresh.nii.gz  0.3  1
    ${ANTSPATH}ThresholdImage 3 kirby_1_imgs/out_mah_oprob${i} temp.nii.gz 0.3 1
    ${ANTSPATH}ImageMath 3 output_mah_${i} DiceAndMinDistSum  kirby_2_imgs/out_mah_oprob${i}_warped_thresh.nii.gz temp.nii.gz Distance_mah_${i}.nii.gz &
done


for i in 01 02 03 04 05 06 07 08 09 10; do
    ${ANTSPATH}WarpImageMultiTransform 3 kirby_2_imgs/out_non_oprob${i}.nii.gz kirby_2_imgs/out_non_oprob${i}_warped.nii.gz -R kirby_fa_1.nii.gz kirby2tokirby1affinedeformed.nii.gz kirby2tokirby1affineAffine.txt 
    ${ANTSPATH}ThresholdImage 3  kirby_2_imgs/out_non_oprob${i}_warped.nii.gz kirby_2_imgs/out_non_oprob${i}_warped_thresh.nii.gz  0.3  1
    ${ANTSPATH}ThresholdImage 3 kirby_1_imgs/out_non_oprob${i} temp.nii.gz 0.3 1
    ${ANTSPATH}ImageMath 3 output_non_${i} DiceAndMinDistSum  kirby_2_imgs/out_non_oprob${i}_warped_thresh.nii.gz temp.nii.gz Distance_non_${i}.nii.gz &
done
