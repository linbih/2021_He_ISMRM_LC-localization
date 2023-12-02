#!/bin/bash
# LC in standard space (MNI152 0.5mm) back to subject structural space 1mm
# use the inverse of previous fnirt Subject T1 brain to MNI152 1mm
# Hengda He, Feb 15 2020

ReD='\033[91m'
YelloW='\033[93m'
EndC='\033[0m'

codepath="/Users/hengdahe/Dropbox/LAB_2020/Linbi/Scripts"
subdir="/Users/hengdahe/Dropbox/LAB_2020/Linbi/LC_Localization_2020_Feb"

SUBJECTS=(180607_Sub11 180618_Sub17 180624_Sub21 180725_Sub25 180829_Sub33 180608_Sub12 180621_Sub18 180626_Sub22 180807_Sub29 180830_Sub34 180612_Sub14 180622_Sub19 180724_Sub23 180808_Sub30 180830_Sub35 180614_Sub15 180623_Sub20 180724_Sub24 180828_Sub32) # All

for SUB in ${SUBJECTS[*]};    
do echo ${SUB}

mkdir ${subdir}/${SUB}/registration_1mm/LC_atlasinT1
regdir=${subdir}/${SUB}/registration_1mm
suboutdir=${subdir}/${SUB}/registration_1mm/LC_atlasinT1

atlasdir="${subdir%/*}/LC_1SD_2SD_Keren_Neuroimage_2009"
T1head=`ls ${subdir}/${SUB}/${SUB}_STRUCT_bias_removed.nii.gz`
T1brain=`ls ${subdir}/${SUB}/${SUB}_STRUCT_bias_removed_brain.nii.gz`
TSEimg=`ls ${subdir}/${SUB}/${SUB}_TSE.nii.gz`
strandardhead="${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz"
strandardbrain_05mm="${atlasdir}/MNI152_T1_0.5mm_brain.nii.gz"
strandardbrain_1mm="${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz"
LCatlas_1SD="${atlasdir}/LC_1SD_BINARY_TEMPLATE.nii"
LCatlas_2SD="${atlasdir}/LC_2SD_BINARY_TEMPLATE.nii"
LCatlas_2SD_label="${atlasdir}/LC_2SD_BINARY_TEMPLATE_label.nii"

# T1 brain to MNI152 1mm brain, non-linear registration
fnirtresult=`ls -ld ${regdir}/T1brain2strandardbrain_warp.nii.gz | wc -l`
if [ $fnirtresult = "1" ]; then
	echo -e "${YelloW} fnirt result exists, inverse warp T1brain2strandardbrain_warp ${EndC}"
invwarp --ref=${T1head} --warp=${regdir}/T1brain2strandardbrain_warp.nii.gz --out=${suboutdir}/T1brain2strandardbrain_warp_inv.nii.gz

    echo "apply warping to LC Atlas"
    applywarp --ref=${T1head} --in=${LCatlas_1SD} --warp=${suboutdir}/T1brain2strandardbrain_warp_inv.nii.gz --out=${suboutdir}/LC_1SD_BINARY_TEMPLATE_StructSpace.nii.gz --interp=nn

    applywarp --ref=${T1head} --in=${LCatlas_2SD} --warp=${suboutdir}/T1brain2strandardbrain_warp_inv.nii.gz --out=${suboutdir}/LC_2SD_BINARY_TEMPLATE_StructSpace.nii.gz --interp=nn

    applywarp --ref=${T1head} --in=${LCatlas_2SD_label} --warp=${suboutdir}/T1brain2strandardbrain_warp_inv.nii.gz --out=${suboutdir}/LC_2SD_LABEL_TEMPLATE_StructSpace.nii.gz --interp=nn

else
	echo -e "${YelloW} ERROR: fnirt T1brain to strandardbrain non-exist ${EndC}"
fi



echo -e "${YelloW} done ${EndC}"

done
