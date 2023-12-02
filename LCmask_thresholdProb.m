clear all; clc; close all;

codepath = '/home/hh2699/Lab/Linbi/Scripts/';
subdir = '/home/hh2699/Lab/Linbi/Subjects/';
addpath('/home/hh2699/Software/niftitool')

 subjects = {'180607_Sub11','180621_Sub18','180724_Sub23','180828_Sub32' ...
 ,'180608_Sub12','180622_Sub19','180724_Sub24','180829_Sub33' ...
 ,'180612_Sub14','180623_Sub20','180725_Sub25','180830_Sub34' ...
 ,'180614_Sub15','180624_Sub21','180807_Sub29','180830_Sub35' ...
 ,'180618_Sub17','180626_Sub22','180808_Sub30'}; % All

for sub = 1:length(subjects)
    disp(['Subject - ',subjects{sub}])

    [a b]=unix(['ls /home/hh2699/Lab/Linbi/Subjects/',subjects{sub},'/',subjects{sub},'_Run*_FUNC_bias_removed.nii.gz']);
    a=convertCharsToStrings(b);
    runnums=length(strfind(a,'Run'));

    for run = 1:runnums
        
        RUN = ['Run',num2str(run)];
        disp(RUN)
   
        suboutdir=[subdir,subjects{sub},'/Stru2EPI_co_reg/',RUN];
        %% load images
    
        LCmask_1SD_1=load_untouch_nii([suboutdir,'/LC_1SD_TEMPLATE_',RUN,'_FuncSpace_1.nii.gz']);
        
        LCmask_1SD_2=load_untouch_nii([suboutdir,'/LC_1SD_TEMPLATE_',RUN,'_FuncSpace_2.nii.gz']);

        LCmask_1SD_LM_1=load_untouch_nii([suboutdir,'/LC_1SD_TEMPLATE_',RUN,'_FuncSpace_LocalMax_1.nii.gz']);
        
        LCmask_1SD_LM_2=load_untouch_nii([suboutdir,'/LC_1SD_TEMPLATE_',RUN,'_FuncSpace_LocalMax_2.nii.gz']);
        
        LCmask_2SD_1=load_untouch_nii([suboutdir,'/LC_2SD_TEMPLATE_',RUN,'_FuncSpace_1.nii.gz']);
        
        LCmask_2SD_2=load_untouch_nii([suboutdir,'/LC_2SD_TEMPLATE_',RUN,'_FuncSpace_2.nii.gz']);

        %% threshold
        
        suboutdirresult=[suboutdir,'/FinalLCMask'];
        mkdir(suboutdirresult)
        % 1SD Template
        LCmask_1SD_1_img = LCmask_1SD_1.img;
        LCmask_1SD_onevox = zeros(size(LCmask_1SD_1_img));
        LCmask_1SD_trivox = zeros(size(LCmask_1SD_1_img));
        
        intensities = sort(LCmask_1SD_1_img(find(LCmask_1SD_1_img>0)), 'descend');
        LCmask_1SD_onevox(find(LCmask_1SD_1_img>(intensities(1)-0.0001))) = 1;
        LCmask_1SD_trivox(find(LCmask_1SD_1_img>(intensities(3)-0.0001))) = 1;
        
        LCmask_1SD_2_img = LCmask_1SD_2.img;
        intensities = sort(LCmask_1SD_2_img(find(LCmask_1SD_2_img>0)), 'descend');
        
        LCmask_1SD_onevox(find(LCmask_1SD_2_img>(intensities(1)-0.0001))) = 1;
        LCmask_1SD_trivox(find(LCmask_1SD_2_img>(intensities(3)-0.0001))) = 1;
        
        %normalize
        LCmask_1SD_onevox_prob = LCmask_1SD_onevox .* (LCmask_1SD_2_img+LCmask_1SD_1_img);
        LCmask_1SD_trivox_prob = LCmask_1SD_trivox .* (LCmask_1SD_2_img+LCmask_1SD_1_img);
        LCmask_1SD_onevox_prob = LCmask_1SD_onevox_prob ./ sum(LCmask_1SD_onevox_prob(find(LCmask_1SD_onevox_prob>0)));
        LCmask_1SD_trivox_prob = LCmask_1SD_trivox_prob ./ sum(LCmask_1SD_trivox_prob(find(LCmask_1SD_trivox_prob>0)));
        
        nii.img = LCmask_1SD_onevox;
        nii.hdr = LCmask_1SD_1.hdr;
        save_nii(nii,[suboutdirresult,'/LC_1SD_TEMPLATE_',RUN,'_FuncSpace_twovoxs.nii.gz'])
        
        nii.img = LCmask_1SD_trivox;
        nii.hdr = LCmask_1SD_1.hdr;
        save_nii(nii,[suboutdirresult,'/LC_1SD_TEMPLATE_',RUN,'_FuncSpace_sixvoxs.nii.gz'])
        
        nii.img = LCmask_1SD_onevox_prob;
        nii.hdr = LCmask_1SD_1.hdr;
        save_nii(nii,[suboutdirresult,'/LC_1SD_TEMPLATE_',RUN,'_FuncSpace_twovoxs_prob.nii.gz'])
        
        nii.img = LCmask_1SD_trivox_prob;
        nii.hdr = LCmask_1SD_1.hdr;
        save_nii(nii,[suboutdirresult,'/LC_1SD_TEMPLATE_',RUN,'_FuncSpace_sixvoxs_prob.nii.gz'])
        
        % 1SD Local Max
        LCmask_1SD_LM_1_img = LCmask_1SD_LM_1.img;
        LCmask_1SD_LM_onevox = zeros(size(LCmask_1SD_LM_1_img));
        LCmask_1SD_LM_trivox = zeros(size(LCmask_1SD_LM_1_img));
        
        intensities = sort(LCmask_1SD_LM_1_img(find(LCmask_1SD_LM_1_img>0)), 'descend');
        LCmask_1SD_LM_onevox(find(LCmask_1SD_LM_1_img>(intensities(1)-0.0001))) = 1;
        LCmask_1SD_LM_trivox(find(LCmask_1SD_LM_1_img>(intensities(3)-0.0001))) = 1;
        
        LCmask_1SD_LM_2_img = LCmask_1SD_LM_2.img;
        intensities = sort(LCmask_1SD_LM_2_img(find(LCmask_1SD_LM_2_img>0)), 'descend');
        
        LCmask_1SD_LM_onevox(find(LCmask_1SD_LM_2_img>(intensities(1)-0.0001))) = 1;
        LCmask_1SD_LM_trivox(find(LCmask_1SD_LM_2_img>(intensities(3)-0.0001))) = 1;
        
        %normalize
        LCmask_1SD_LM_onevox_prob = LCmask_1SD_LM_onevox .* (LCmask_1SD_LM_2_img+LCmask_1SD_LM_1_img);
        LCmask_1SD_LM_trivox_prob = LCmask_1SD_LM_trivox .* (LCmask_1SD_LM_2_img+LCmask_1SD_LM_1_img);
        LCmask_1SD_LM_onevox_prob = LCmask_1SD_LM_onevox_prob ./ sum(LCmask_1SD_LM_onevox_prob(find(LCmask_1SD_LM_onevox_prob>0)));
        LCmask_1SD_LM_trivox_prob = LCmask_1SD_LM_trivox_prob ./ sum(LCmask_1SD_LM_trivox_prob(find(LCmask_1SD_LM_trivox_prob>0)));
        
        nii.img = LCmask_1SD_LM_onevox;
        nii.hdr = LCmask_1SD_LM_1.hdr;
        save_nii(nii,[suboutdirresult,'/LC_1SD_LM_',RUN,'_FuncSpace_twovoxs.nii.gz'])
        
        nii.img = LCmask_1SD_LM_trivox;
        nii.hdr = LCmask_1SD_LM_1.hdr;
        save_nii(nii,[suboutdirresult,'/LC_1SD_LM_',RUN,'_FuncSpace_sixvoxs.nii.gz'])
        
        nii.img = LCmask_1SD_LM_onevox_prob;
        nii.hdr = LCmask_1SD_LM_1.hdr;
        save_nii(nii,[suboutdirresult,'/LC_1SD_LM_',RUN,'_FuncSpace_twovoxs_prob.nii.gz'])
        
        nii.img = LCmask_1SD_LM_trivox_prob;
        nii.hdr = LCmask_1SD_LM_1.hdr;
        save_nii(nii,[suboutdirresult,'/LC_1SD_LM_',RUN,'_FuncSpace_sixvoxs_prob.nii.gz'])
        
        % 2SD Template
        LCmask_2SD_1_img = LCmask_2SD_1.img;
        LCmask_2SD_sixvox = zeros(size(LCmask_2SD_1_img));
        
        intensities = sort(LCmask_2SD_1_img(find(LCmask_2SD_1_img>0)), 'descend');
        LCmask_2SD_sixvox(find(LCmask_2SD_1_img>(intensities(6)-0.0001))) = 1;
        
        LCmask_2SD_2_img = LCmask_2SD_2.img;
        intensities = sort(LCmask_2SD_2_img(find(LCmask_2SD_2_img>0)), 'descend');
        
        LCmask_2SD_sixvox(find(LCmask_2SD_2_img>(intensities(6)-0.0001))) = 1;
        
        LCmask_2SD_sixvox_prob = LCmask_2SD_sixvox .* (LCmask_2SD_2_img+LCmask_2SD_1_img);
        LCmask_2SD_sixvox_prob = LCmask_2SD_sixvox_prob ./ sum(LCmask_2SD_sixvox_prob(find(LCmask_2SD_sixvox_prob>0)));
        
        nii.img = LCmask_2SD_sixvox;
        nii.hdr = LCmask_2SD_1.hdr;
        save_nii(nii,[suboutdirresult,'/LC_2SD_TEMPLATE_',RUN,'_FuncSpace_twelvevoxs.nii.gz'])
        
        nii.img = LCmask_2SD_sixvox_prob;
        nii.hdr = LCmask_2SD_1.hdr;
        save_nii(nii,[suboutdirresult,'/LC_2SD_TEMPLATE_',RUN,'_FuncSpace_twelvevoxs_prob.nii.gz'])
        
    end
    
end

