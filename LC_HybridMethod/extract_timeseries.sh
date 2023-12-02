#!/bin/bash
# regress out nuisance signal from preprocessed filtered_func_data.nii.gz
# extract time series from ROI with weight
# Hengda He, May 4 2020

ReD='\033[91m'
YelloW='\033[93m'
EndC='\033[0m'

subdir="/home/hh2699/Lab/Linbi/Subjects"

SUBJECTS=(180607_Sub11 180618_Sub17 180624_Sub21 180725_Sub25 180829_Sub33 180608_Sub12 180621_Sub18 180626_Sub22 180807_Sub29 180830_Sub34 180612_Sub14 180622_Sub19 180724_Sub23 180808_Sub30 180830_Sub35 180614_Sub15 180623_Sub20 180724_Sub24 180828_Sub32) # all

for SUB in ${SUBJECTS[*]};    
do echo ${SUB}

    regpath=${subdir}/${SUB}/Stru2EPI_co_reg
    outputdir=${subdir}/${SUB}/ROIanalysis

    rm ${outputdir}/${SUB}_LC_1SD_template_2voxs.txt
    rm ${outputdir}/${SUB}_LC_1SD_template_6voxs.txt
    rm ${outputdir}/${SUB}_LC_1SD_Hybrid_2voxs.txt
    rm ${outputdir}/${SUB}_LC_1SD_Hybrid_6voxs.txt
    rm ${outputdir}/${SUB}_LC_2SD_template_12voxs.txt

    for runpath in `ls ${subdir}/${SUB}/${SUB}_Run*_FUNC_bias_removed.nii.gz`;
    do 

        runnum=${runpath##*${SUB}_}
        runnum=${runnum%%_FUNC_bias_removed.nii.gz*}
        echo "fMRI run #: "${runnum}

        ## LC masks and weights
        suboutdir=${regpath}/${runnum}

        LCmask_1SD_2voxs=`ls ${suboutdir}/FinalLCMask/LC_1SD_TEMPLATE_${runnum}_FuncSpace_twovoxs.nii.gz`
        LCmask_1SD_6voxs=`ls ${suboutdir}/FinalLCMask/LC_1SD_TEMPLATE_${runnum}_FuncSpace_sixvoxs.nii.gz`
        LCmask_1SD_2voxs_prob=`ls ${suboutdir}/FinalLCMask/LC_1SD_TEMPLATE_${runnum}_FuncSpace_twovoxs_prob.nii.gz`
        LCmask_1SD_6voxs_prob=`ls ${suboutdir}/FinalLCMask/LC_1SD_TEMPLATE_${runnum}_FuncSpace_sixvoxs_prob.nii.gz`

        LCmask_1SD_Hybrid_2voxs=`ls ${suboutdir}/FinalLCMask/LC_1SD_Hybrid_${runnum}_FuncSpace_twovoxs.nii.gz`
        LCmask_1SD_Hybrid_6voxs=`ls ${suboutdir}/FinalLCMask/LC_1SD_Hybrid_${runnum}_FuncSpace_sixvoxs.nii.gz`
        LCmask_1SD_Hybrid_2voxs_prob=`ls ${suboutdir}/FinalLCMask/LC_1SD_Hybrid_${runnum}_FuncSpace_twovoxs_prob.nii.gz`
        LCmask_1SD_Hybrid_6voxs_prob=`ls ${suboutdir}/FinalLCMask/LC_1SD_Hybrid_${runnum}_FuncSpace_sixvoxs_prob.nii.gz`

        LCmask_2SD_12voxs=`ls ${suboutdir}/FinalLCMask/LC_2SD_TEMPLATE_${runnum}_FuncSpace_twelvevoxs.nii.gz`
        LCmask_2SD_12voxs_prob=`ls ${suboutdir}/FinalLCMask/LC_2SD_TEMPLATE_${runnum}_FuncSpace_twelvevoxs_prob.nii.gz`

        ## regress out nuisance signal
        featoutput=${outputdir}/Preprocessing_${runnum}.feat
        echo "Calculate motion parameters (standard + extension)"
        ${FSLDIR}/bin/mp_diffpow.sh ${featoutput}/mc/prefiltered_func_data_mcf.par ${featoutput}/mc/prefiltered_func_data_mcf_diff
        paste -d ' ' ${featoutput}/mc/prefiltered_func_data_mcf.par ${featoutput}/mc/prefiltered_func_data_mcf_diff.dat  > ${featoutput}/mc/prefiltered_func_data_mcf_final.par

        ## feat preprocessed data
        preprocessedfmri=`ls ${featoutput}/filtered_func_data.nii.gz`
        echo "Preprocessed fMRI: "${preprocessedfmri}

        # scale to percent signal change Y/mean(Y)*100
        echo "scale to percent signal change Y/mean(Y)*100"
        fslmaths ${featoutput}/filtered_func_data.nii.gz -Tmean ${featoutput}/tempMean.nii.gz
        fslmaths ${featoutput}/filtered_func_data.nii.gz -div ${featoutput}/tempMean.nii.gz -mul 100 ${featoutput}/filtered_func_data_PSC.nii.gz
        preprocessedfmri_psc=${featoutput}/filtered_func_data_PSC.nii.gz

        ## extract time series from 4th ventricle
        ventricle4th=`ls ${subdir}/${SUB}/FS2EPI_co_reg/${runnum}/Ventricle4th_${runnum}_FuncSpace.nii.gz`

        fslmeants -i ${featoutput}/filtered_func_data_PSC.nii.gz -o ${featoutput}/ROI_4thventricle_timeseries.txt -m ${ventricle4th}

        paste -d  ' '  ${featoutput}/mc/prefiltered_func_data_mcf_final.par ${featoutput}/ROI_4thventricle_timeseries.txt > ${featoutput}/confoundevs.txt

        # glm regress out
        Text2Vest ${featoutput}/confoundevs.txt ${featoutput}/confoundevs.mat

        pushd ${featoutput}
        fsl_glm -i filtered_func_data_PSC.nii.gz  --demean -d confoundevs.mat --out_res=residual.nii.gz --out_z=motionsignal.nii.gz --out_cope=motionbeta.nii.gz
        popd

        # add back mean image
        fslmaths ${featoutput}/residual.nii.gz -add 100 ${featoutput}/filtered_func_data_nuisance_regress.nii.gz

        cp ${featoutput}/residual.nii.gz ${featoutput}/filtered_func_data_nuisance_regress_residual.nii.gz
        ## regressison finished
        echo "fMRI (Nuisance signal regressed out): "${featoutput}/filtered_func_data_nuisance_regress_residual.nii.gz

        # extract time series from mask with weight
        fslmeants -i ${featoutput}/filtered_func_data_nuisance_regress_residual.nii.gz -o ${featoutput}/LC_timeseries_1SD_template_2voxs.txt -m ${LCmask_1SD_2voxs_prob} -w
        fslmeants -i ${featoutput}/filtered_func_data_nuisance_regress_residual.nii.gz -o ${featoutput}/LC_timeseries_1SD_template_6voxs.txt -m ${LCmask_1SD_6voxs_prob} -w

        fslmeants -i ${featoutput}/filtered_func_data_nuisance_regress_residual.nii.gz -o ${featoutput}/LC_timeseries_1SD_Hybrid_2voxs.txt -m ${LCmask_1SD_Hybrid_2voxs_prob} -w
        fslmeants -i ${featoutput}/filtered_func_data_nuisance_regress_residual.nii.gz -o ${featoutput}/LC_timeseries_1SD_Hybrid_6voxs.txt -m ${LCmask_1SD_Hybrid_6voxs_prob} -w

        fslmeants -i ${featoutput}/filtered_func_data_nuisance_regress_residual.nii.gz -o ${featoutput}/LC_timeseries_2SD_template_12voxs.txt -m ${LCmask_2SD_12voxs_prob} -w

        cat ${featoutput}/LC_timeseries_1SD_template_2voxs.txt >> ${outputdir}/${SUB}_LC_1SD_template_2voxs.txt
        cat ${featoutput}/LC_timeseries_1SD_template_6voxs.txt >> ${outputdir}/${SUB}_LC_1SD_template_6voxs.txt
        cat ${featoutput}/LC_timeseries_1SD_Hybrid_2voxs.txt >> ${outputdir}/${SUB}_LC_1SD_Hybrid_2voxs.txt
        cat ${featoutput}/LC_timeseries_1SD_Hybrid_6voxs.txt >> ${outputdir}/${SUB}_LC_1SD_Hybrid_6voxs.txt
        cat ${featoutput}/LC_timeseries_2SD_template_12voxs.txt >> ${outputdir}/${SUB}_LC_2SD_template_12voxs.txt

    done

done

echo -e "${YelloW} done ${EndC}"
