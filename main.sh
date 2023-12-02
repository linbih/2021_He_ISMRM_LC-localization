#!/bin/bash
# Structural/T1 to HighRes T2* to Functional/EPI space
# 1. T1 to HighRes T2* with skull, rigid registration, BBR
# 2. HighRes T2* to EPI (middle time volume) with skull, rigid registration
# 3. combined transformation, transform LCmask & T1 into Functional/TPI space
# 4. transform EPI to T1 space (visual inspection)
# Hengda He, Mar 21 2020

matlabpath='/Applications/MATLAB_R2020b.app/bin/matlab'
subdir='/Users/hengdahe/Dropbox/LAB_2020/Linbi/LC_Localization_2020_Feb'
scriptdir='/Users/hengdahe/Dropbox/LAB_2021/Linbi/Scripts_share'

mkdir log

echo "Running Subject_Classification_Criterion"
${matlabpath} -nodesktop -nodisplay -r "Subject_Classification_Criterion('${subdir}/','${scriptdir}/');quit;" >& 'log/Subject_Classification_Criterion.txt'
echo "Finished - Subject_Classification_Criterion"

## initial good - use 1SD TSE
#SUBJECTS=(180607_Sub11 180618_Sub17 180725_Sub25 180829_Sub33 180608_Sub12 180621_Sub18 180724_Sub24)
echo "Running Subject_Class1_LCin1SD"
for SUB in `cat Subject_Class1_LCin1SD.txt`
do echo ${SUB}
   bash FSLregistration_co_reg_Stru2EPI_applyLCTSE_1SD_BBR.sh ${SUB} ${subdir}
done

## others use TSE 2SD
#SUBJECTS=(180626_Sub22 180807_Sub29 180830_Sub34 180612_Sub14 180622_Sub19 180724_Sub23 180808_Sub30 180830_Sub35 180614_Sub15 180828_Sub32)
echo "Running Subject_Class2_LCin2SD"
for SUB in `cat Subject_Class2_LCin2SD.txt`
do echo ${SUB}

   bash FSLregistration_co_reg_Stru2EPI_applyLCTSE_2SD_BBR.sh ${SUB} ${subdir}

done

## low contrast/distortion - use LC template
#SUBJECTS=(180623_Sub20 180624_Sub21)
echo "Running FSLregistration_co_reg_Stru2EPI_applyLCtemp"
for SUB in `cat Subject_Class3_LCinAtlas.txt` 
do echo ${SUB}

   bash FSLregistration_co_reg_Stru2EPI_applyLCtemp.sh ${SUB} ${subdir}

done

echo "Running FSLregistration_co_reg_Stru2EPI_apply4thV_FS"
bash FSLregistration_co_reg_Stru2EPI_apply4thV_FS.sh ${subdir}

echo "Running LCmask_thresholdProb"
${matlabpath} -nodesktop -nodisplay -r "LCmask_thresholdProb;quit;" >& 'log/LCmask_thresholdProb.txt'

echo "Running extract_timeseries"
bash extract_timeseries.sh

echo "Done"
