#!/bin/bash
# TSE/T1 to standard space (MNI152)
# 1. TSE to T1 with skull, rigid registration
# 2. T1 brain to MNI152 2mm brain, non-linear registration
# 3. combined transformation, warp TSE into MNI152 space, either sampled to 1mm or 2mm
# Hengda He, Jan 24 2020

ReD='\033[91m'
YelloW='\033[93m'
EndC='\033[0m'

codepath="/Users/hengdahe/Dropbox/LAB_2020/Linbi/Scripts"
subdir="/Users/hengdahe/Dropbox/LAB_2020/Linbi/LC_Localization_2020_Feb"

SUBJECTS=(180607_Sub11 180618_Sub17 180624_Sub21 180725_Sub25 180829_Sub33 180608_Sub12 180621_Sub18 180626_Sub22 180807_Sub29 180830_Sub34 180612_Sub14 180622_Sub19 180724_Sub23 180808_Sub30 180830_Sub35 180614_Sub15 180623_Sub20 180724_Sub24 180828_Sub32)

for SUB in ${SUBJECTS[*]};    
do echo ${SUB}

mkdir ${subdir}/${SUB}/registration_1mm
suboutdir=${subdir}/${SUB}/registration_1mm

T1head=`ls ${subdir}/${SUB}/${SUB}_STRUCT_bias_removed.nii.gz`
T1brain=`ls ${subdir}/${SUB}/${SUB}_STRUCT_bias_removed_brain.nii.gz`
TSEimg=`ls ${subdir}/${SUB}/${SUB}_TSE.nii.gz`
strandardhead="${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz"
strandardbrain="${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz"
strandardbrain_1mm="${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz"
standard_mask="${FSLDIR}/data/standard/MNI152_T1_1mm_brain_mask_dil.nii.gz"

# TSE to T1 with skull, rigid registration
flirttseresult=`ls -ld ${suboutdir}/TSE2structhead.mat | wc -l`
if [ $flirttseresult = "1" ]; then
	echo -e "${YelloW} flirt TSE result exists ${EndC}"
else
    echo "TSE to T1 with skull, rigid registration"
    flirt -ref ${T1head} -in ${TSEimg} -dof 6 -omat ${suboutdir}/TSE2structhead.mat -out ${suboutdir}/TSE2structhead.nii.gz
fi


# T1 brain to MNI152 2mm brain, non-linear registration
flirtT1result=`ls -ld ${suboutdir}/T1brain2strandardbrain.mat | wc -l`
if [ $flirtT1result = "1" ]; then
	echo -e "${YelloW} flirt T1 result exists ${EndC}"
else
    echo -e "${YelloW} flirt T1brain to strandardbrain ${EndC}"
    flirt -in ${T1brain} -ref ${strandardbrain} -out ${suboutdir}/T1brain2strandardbrain -omat ${suboutdir}/T1brain2strandardbrain.mat -cost corratio -dof 12 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear 
fi

fnirtresult=`ls -ld ${suboutdir}/T1brain2strandardbrain_warp.nii.gz | wc -l`
if [ $fnirtresult = "1" ]; then
	echo -e "${YelloW} fnirt result exists ${EndC}"
else
	echo -e "${YelloW} fnirt T1brain to strandardbrain ${EndC}"
    fnirt --iout=${suboutdir}/T1brain2strandardhead --in=${T1head} --aff=${suboutdir}/T1brain2strandardbrain.mat --cout=${suboutdir}/T1brain2strandardbrain_warp --iout=${suboutdir}/T1brain2strandardbrain --jout=${suboutdir}/T1brain2T1brain_jac --config=T1_2_MNI152_2mm --ref=${strandardhead} --refmask=${standard_mask} --warpres=10,10,10


fi

echo "apply warping to T1"
applywarp -i ${T1brain} -r ${strandardbrain_1mm} -o ${suboutdir}/T1brain2strandardbrain_1mm -w ${suboutdir}/T1brain2strandardbrain_warp

echo "apply warping to TSE"
convert_xfm -omat ${suboutdir}/TSE2standardbrain.mat -concat ${suboutdir}/T1brain2strandardbrain.mat ${suboutdir}/TSE2structhead.mat
convertwarp --ref=${strandardbrain} --premat=${suboutdir}/TSE2structhead.mat --warp1=${suboutdir}/T1brain2strandardbrain_warp --out=${suboutdir}/TSE2strandardbrain_warp

applywarp --ref=${strandardbrain} --in=${TSEimg} --out=${suboutdir}/TSE2standardbrain_2mm --warp=${suboutdir}/TSE2strandardbrain_warp

applywarp --ref=${strandardbrain_1mm} --in=${TSEimg} --out=${suboutdir}/TSE2standardbrain_1mm --warp=${suboutdir}/TSE2strandardbrain_warp

echo -e "${YelloW} done ${EndC}"

done









