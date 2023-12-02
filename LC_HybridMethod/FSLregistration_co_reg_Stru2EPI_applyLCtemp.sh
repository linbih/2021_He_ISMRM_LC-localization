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
volumn_num='150'

SUBJECTS=$1
subdir=$2

for SUB in ${SUBJECTS[*]};    
do echo ${SUB}

    mkdir ${subdir}/${SUB}/Stru2EPI_co_reg

    LCmask_1SD=`ls ${subdir}/${SUB}/registration_1mm/LC_atlasinT1/LC_1SD_BINARY_TEMPLATE_StructSpace.nii.gz`
    LCmask_1SD_LM=`ls ${subdir}/${SUB}/registration_1mm/LC_atlasinT1/LC_1SD_BINARY_TEMPLATE_StructSpace_LocalMax.nii.gz`
    LCmask_2SD=`ls ${subdir}/${SUB}/registration_1mm/LC_atlasinT1/LC_2SD_BINARY_TEMPLATE_StructSpace.nii.gz`
    LCmask_2SD_label=`ls ${subdir}/${SUB}/registration_1mm/LC_atlasinT1/LC_2SD_LABEL_TEMPLATE_StructSpace.nii.gz`
    T1head=`ls ${subdir}/${SUB}/${SUB}_STRUCT_bias_removed.nii.gz`
    T1brain=`ls ${subdir}/${SUB}/${SUB}_STRUCT_bias_removed_brain.nii.gz`

    TSE_struct=`ls ${subdir}/${SUB}/registration_1mm/TSE2structhead.nii.gz`

    echo "HighRes T2* to T1 with skull, rigid registration, BBR"
    epi_reg --epi=${Highreshead} --t1=${T1head} --t1brain=${T1brain} --out=${subdir}/${SUB}/Stru2EPI_co_reg/FuncHighRes2Struct_epireg

    # transform LCmask & T1 into Functional/TPI space trilinear side-by-side
    fslmaths ${LCmask_2SD_label} -thr 1 -uthr 1 ${subdir}/${SUB}/Stru2EPI_co_reg/LC_2SD_TEMPLATE_StructSpace_1.nii.gz
    fslmaths ${LCmask_2SD_label} -thr 2 -uthr 2 -bin ${subdir}/${SUB}/Stru2EPI_co_reg/LC_2SD_TEMPLATE_StructSpace_2.nii.gz

    fslmaths ${LCmask_1SD} -mul ${subdir}/${SUB}/Stru2EPI_co_reg/LC_2SD_TEMPLATE_StructSpace_1.nii.gz ${subdir}/${SUB}/Stru2EPI_co_reg/LC_1SD_TEMPLATE_StructSpace_1.nii.gz
    fslmaths ${LCmask_1SD} -mul ${subdir}/${SUB}/Stru2EPI_co_reg/LC_2SD_TEMPLATE_StructSpace_2.nii.gz ${subdir}/${SUB}/Stru2EPI_co_reg/LC_1SD_TEMPLATE_StructSpace_2.nii.gz

    cp ${subdir}/${SUB}/Stru2EPI_co_reg/LC_1SD_TEMPLATE_StructSpace_1.nii.gz ${subdir}/${SUB}/Stru2EPI_co_reg/LC_1SD_TEMPLATE_StructSpace_LocalMax_1.nii.gz

    cp ${subdir}/${SUB}/Stru2EPI_co_reg/LC_1SD_TEMPLATE_StructSpace_2.nii.gz ${subdir}/${SUB}/Stru2EPI_co_reg/LC_1SD_TEMPLATE_StructSpace_LocalMax_2.nii.gz

    #for runnum in ${RUNS[*]};
    for runpath in `ls ${subdir}/${SUB}/${SUB}_Run*_FUNC_bias_removed.nii.gz`;
    do 

        runnum=${runpath##*${SUB}_}
        runnum=${runnum%%_FUNC_bias_removed.nii.gz*}
        echo "fMRI run #: "${runnum}

        mkdir ${subdir}/${SUB}/Stru2EPI_co_reg/${runnum}
        suboutdir=${subdir}/${SUB}/Stru2EPI_co_reg/${runnum}

        fMRIimg=`ls ${subdir}/${SUB}/${SUB}_${runnum}_FUNC_bias_removed.nii.gz`

        midvolnum=$((volumn_num / 2))
        fmrirun=${fMRIimg##*Run}
        fslroi $fMRIimg ${suboutdir}/Run${fmrirun%%.*}_midvol.nii.gz $midvolnum 1
        epiimg=`ls ${suboutdir}/Run${fmrirun%%.*}_midvol.nii.gz`

        # T1 to HighRes T2* with skull, rigid registration, BBR
        echo "HighRes T2* to T1 without skull, rigid registration, BBR, copy result"
        cp ${subdir}/${SUB}/Stru2EPI_co_reg/FuncHighRes2Struct_epireg.mat ${suboutdir}/

        #EPI (middle time volume) to HighRes func without skull, rigid registration
        flirt -ref ${Highreshead} -in ${epiimg} -dof 6 -omat ${suboutdir}/epi2HRfunc.mat -out ${suboutdir}/epi2HRfunc

        # combined & invert transformations
        convert_xfm -omat ${suboutdir}/epi2struc.mat -concat ${suboutdir}/FuncHighRes2Struct_epireg.mat ${suboutdir}/epi2HRfunc.mat
        convert_xfm -omat ${suboutdir}/struc2epi.mat -inverse ${suboutdir}/epi2struc.mat

        cp ${subdir}/${SUB}/Stru2EPI_co_reg/LC_1SD_TEMPLATE_StructSpace_LocalMax_1.nii.gz ${suboutdir}/
        cp ${subdir}/${SUB}/Stru2EPI_co_reg/LC_1SD_TEMPLATE_StructSpace_LocalMax_2.nii.gz ${suboutdir}/

        # apply trilinear transform
        flirt -in ${suboutdir}/LC_1SD_TEMPLATE_StructSpace_LocalMax_1.nii.gz -ref ${epiimg} -applyxfm -init ${suboutdir}/struc2epi.mat -out ${suboutdir}/LC_1SD_TEMPLATE_Run${fmrirun%%_*}_FuncSpace_LocalMax_1.nii.gz -interp trilinear
        flirt -in ${suboutdir}/LC_1SD_TEMPLATE_StructSpace_LocalMax_2.nii.gz -ref ${epiimg} -applyxfm -init ${suboutdir}/struc2epi.mat -out ${suboutdir}/LC_1SD_TEMPLATE_Run${fmrirun%%_*}_FuncSpace_LocalMax_2.nii.gz -interp trilinear

        # Transform EPI to T1 space (visual inspection)
        # flirt -in ${epiimg} -ref ${T1head} -applyxfm -init ${suboutdir}/epi2struc.mat -out ${epiimg%%.*}_StructSpace.nii.gz

    done

done

echo -e "${YelloW} done ${EndC}"
