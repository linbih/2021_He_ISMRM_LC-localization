### This repository contains code for:

H He, L Hong, P Sajda (2021). An Automatic and Subject-specific Method for Locus Coeruleus Localization and BOLD Activity Extraction. Proceedings of the International Society for Magnetic Resonance in Medicine 2021. [Link](https://www.ismrm.org/21/program-files/TeaserSlides/TeasersPresentations/2711-Teaser.html)
.

### Code specifics

1. Subject TSE image space and MNI standard space registration
   1) TSEandMNI_registration/FSLregistration_TSE_1mm.sh
        - Input: TSE_image, T1_image, standard_image              
            -  a. Rigid registration of TSE image to T1_head
            -  b. T1_brain non-linear registration to MNI_standard_brain
        -  Output: TSE2structhead.mat, T1brain2strandardbrain_warp.nii.gz, TSE2strandardbrain_warp.nii.gz

    2) TSEandMNI_registration/LCmask_MNI2SUB.sh
       - Input: LC_atlas
           - Warp LC_atlas into subject structural space.
       - Output: LC_template in Structspace

2. Hybrid method to locate LC in functional space, and extract time series
    1) LC_HybridMethod/main.sh

    2) LC_HybridMethod/Subject_Classification_Criterion.m
        - Input: TSE_image_in_T1Structuralspace, LC_template in StructuralSpace
        - Move voxels in 1SD template to local max with constraints
        - Output: Statistics and classification of subjects into groups for Hybrid method.

    3) LC_HybridMethod/FSLregistration_co_reg_Stru2EPI_applyLCTSE_1SD_BBR.sh
        - Input: TSE in StructuralSpace, LC_template in StructuralSpace
            - a. BBR registration of high_res_head and T1_image_head
            - b. Mask TSE image with LC_1SD_template in Structural Space
            - c. EPI_head rigid registration to high_res_head
            - d. Transform Masked_TSEintensities_inLC1SD_Template from structural space to functional space

        - Output: TSE_images masked with LC_template_1SD in functional space

    4) LC_HybridMethod/FSLregistration_co_reg_Stru2EPI_applyLCTSE_2SD_BBR.sh
        - Output: TSE_images masked with LC_template_2SD in functional space

    5) LC_HybridMethod/FSLregistration_co_reg_Stru2EPI_applyLCtemp.sh
        - Output: LC_1SD_template_binary_mask trilinear interpolated into functional space

    6) LC_HybridMethod/LCmask_thresholdProb.m
        - Input: trilinear interpolated LC TSEintensities or mask in functional space
        - Output: LC location in functional space with 2 Vox version and 6 Vox version

    7) LC_HybridMethod/fsl_preprocessing_feat.sh
        - Input: fMRI
            - No spatial smoothing. Slice timing correction, motion correction, temporal filtering
        - Output: preprocessed fMRI 

    8) LC_HybridMethod/FSLregistration_co_reg_Stru2EPI_apply4thV_FS.sh
        - Input: Freesurfer segmentation, T1, highres and EPI images
    
            - a. Extract 4th ventricle mask in Freesurfer space
            - b. BBR registration of Freesurfer space and high res space
            - c. Rigid registration of EPI functional space and high res space
            - d. Transform 4th ventricle binary mask from Freesurfer space to functional space

    9) LC_HybridMethod/extract_timeseries.sh
        - Input: LC location and probability in functional space (2 Vox and 6 vox), preprocessed fMRI.
    
            - a. scale fMRI into percent signal change
            - b. Extract time series from 4th ventricle
            - c. GLM to regress out motion parameters (standard and extended) and 4th ventricle time series.
            - d. Extract time series in LC locations weighted with LC location probabilities from GLM residual.
    
        - Output: LC time series (2 vox and 6 vox versions)
