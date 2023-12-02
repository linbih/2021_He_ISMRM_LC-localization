#!/bin/bash
# Structural/T1 to HighRes T2* to Functional/EPI space
# 1. T1 to HighRes T2* with skull, rigid registration, BBR
# 2. HighRes T2* to EPI (middle time volume) with skull, rigid registration
# 3. combined transformation, transform LCmask & T1 into Functional/TPI space
# 4. transform EPI to T1 space (visual inspection)
# Hengda He, Mar 21 2020

ReD='\033[91m'
YelloW='\033[93m'
EndC='\033[0m'

#subdir="/home/hh2699/Lab/Linbi/Subjects"
subdir=$1
volumn_num='150'

SUBJECTS=(180607_Sub11 180618_Sub17 180624_Sub21 180725_Sub25 180829_Sub33 180608_Sub12 180621_Sub18 180626_Sub22 180807_Sub29 180830_Sub34 180612_Sub14 180622_Sub19 180724_Sub23 180808_Sub30 180830_Sub35 180623_Sub20 180724_Sub24 180828_Sub32)

for SUB in ${SUBJECTS[*]};    
do echo ${SUB}

    mkdir ${subdir}/${SUB}/FS2EPI_co_reg

    mri_convert ${subdir}/${SUB}/FreeSurfer/mri/wmparc.mgz ${subdir}/${SUB}/FS2EPI_co_reg/wmparc.nii.gz

    fslmaths ${subdir}/${SUB}/FS2EPI_co_reg/wmparc.nii.gz -thr 15 -uthr 15 -bin ${subdir}/${SUB}/FS2EPI_co_reg/ROI_4thventricle.nii.gz

    mri_convert ${subdir}/${SUB}/FreeSurfer/mri/nu.mgz ${subdir}/${SUB}/FS2EPI_co_reg/nu.nii.gz
    mri_convert ${subdir}/${SUB}/FreeSurfer/mri/brain.mgz ${subdir}/${SUB}/FS2EPI_co_reg/brain.nii.gz

    ventricle4=`ls ${subdir}/${SUB}/FS2EPI_co_reg/ROI_4thventricle.nii.gz`

    T1head=`ls ${subdir}/${SUB}/FS2EPI_co_reg/nu.nii.gz`
    T1brain=`ls ${subdir}/${SUB}/FS2EPI_co_reg/brain.nii.gz`
    Highreshead=`ls ${subdir}/${SUB}/${SUB}_Highres_bias_removed.nii.gz`

    echo "HighRes T2* to T1 with skull, rigid registration, BBR"
    flirt -ref ${T1head} -in ${Highreshead} -cost normmi -dof 6 -omat ${subdir}/${SUB}/FS2EPI_co_reg/FuncHighRes2Struct.mat -out ${subdir}/${SUB}/FS2EPI_co_reg/FuncHighRes2Struct

    for runpath in `ls ${subdir}/${SUB}/${SUB}_Run*_FUNC_bias_removed.nii.gz`;
    do 

        runnum=${runpath##*${SUB}_}
        runnum=${runnum%%_FUNC_bias_removed.nii.gz*}
        echo "fMRI run #: "${runnum}

        mkdir ${subdir}/${SUB}/FS2EPI_co_reg/${runnum}
        suboutdir=${subdir}/${SUB}/FS2EPI_co_reg/${runnum}

        fMRIimg=`ls ${subdir}/${SUB}/${SUB}_${runnum}_FUNC_bias_removed.nii.gz`

        midvolnum=$((volumn_num / 2))
        fmrirun=${fMRIimg##*Run}
        fslroi $fMRIimg ${suboutdir}/Run${fmrirun%%.*}_midvol.nii.gz $midvolnum 1
        epiimg=`ls ${suboutdir}/Run${fmrirun%%.*}_midvol.nii.gz`

        # T1 to HighRes T2* with skull, rigid registration, BBR
        echo "HighRes T2* to T1 with skull, rigid registration, BBR, copy result"
        cp ${subdir}/${SUB}/FS2EPI_co_reg/FuncHighRes2Struct.mat ${suboutdir}/

        # EPI (middle time volume) to HighRes func without skull, rigid registration
        flirt -ref ${Highreshead} -in ${epiimg} -dof 6 -omat ${suboutdir}/epi2HRfunc.mat -out ${suboutdir}/epi2HRfunc

        # combined & invert transformations
        convert_xfm -omat ${suboutdir}/epi2struc.mat -concat ${suboutdir}/FuncHighRes2Struct.mat ${suboutdir}/epi2HRfunc.mat
        convert_xfm -omat ${suboutdir}/struc2epi.mat -inverse ${suboutdir}/epi2struc.mat

        # apply nn transform
        flirt -in ${ventricle4} -ref ${epiimg} -applyxfm -init ${suboutdir}/struc2epi.mat -out ${suboutdir}/Ventricle4th_Run${fmrirun%%_*}_FuncSpace.nii.gz -interp nearestneighbour

        # Transform EPI to T1 space (visual inspection)
        flirt -in ${epiimg} -ref ${T1head} -applyxfm -init ${suboutdir}/epi2struc.mat -out ${epiimg%%.*}_FSSpace.nii.gz
        
    done

done

echo -e "${YelloW} done ${EndC}"
