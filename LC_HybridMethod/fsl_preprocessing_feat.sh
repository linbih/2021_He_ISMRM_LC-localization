#!/bin/bash
################################################################################
# ROI analysis preprocessing
#                by Hengda He
#               April 20 2020
################################################################################

SUBJECTS=(180607_Sub11 180618_Sub17 180624_Sub21 180725_Sub25 180829_Sub33 180608_Sub12 180621_Sub18 180626_Sub22 180807_Sub29 180830_Sub34 180612_Sub14 180622_Sub19 180724_Sub23 180808_Sub30 180830_Sub35 180614_Sub15 180623_Sub20 180724_Sub24 180828_Sub32) # all

scriptdir="/Users/hengdahe/Dropbox/LAB_2021/Linbi/Scripts_share"
subdir="/home/hh2699/Lab/Linbi/Subjects"

echo "Subject directory: "${subdir}
echo "Script directory: "${scriptdir}

for SUB in ${SUBJECTS[*]}; 
do echo "Subject ID: "${SUB}

    outputdir=${subdir}/${SUB}/ROIanalysis
    mkdir ${outputdir} 2>/dev/null
    echo "Output directory: "${outputdir}

    for runpath in `ls ${subdir}/${SUB}/${SUB}_Run*_FUNC_bias_removed.nii.gz`;
    do
        runnum=${runpath##*${SUB}_}
        runnum=${runnum%%_FUNC_bias_removed.nii.gz*}
        echo "fMRI run #: "${runnum}

        cp ${scriptdir}/ROIanalysis_preprocessing_design.fsf ${outputdir}/ROIanalysis_preprocessing_DesignFile_${SUB}_${runnum}.fsf
        DesignFileName=${outputdir}/ROIanalysis_preprocessing_DesignFile_${SUB}_${runnum}.fsf
        echo "Make disign file: "${DesignFileName}

        inputfmri=`ls ${subdir}/${SUB}/${SUB}_${runnum}_FUNC_bias_removed.nii.gz`

        featoutput=${outputdir}/Preprocessing_${runnum}
        sed -i 's:<<<OutputDir>>>:'${featoutput}':' ${DesignFileName}
        sed -i 's:<<<InputFMRI>>>:'${inputfmri}':' ${DesignFileName}

        echo "Input fMRI: "${inputfmri}
        echo "Output Dir: "${featoutput}

        echo "Submitting feat"

        feat ${DesignFileName}
    done

done



