
function Subject_Classification_Criterion(subdir,scriptdir)

%     subdir = '/Users/hengdahe/Dropbox/LAB_2020/Linbi/LC_Localization_2020_Feb/';
    reg_foldername = 'registration_1mm';
    LC_foldername = 'LC_atlasinT1';
%     scriptdir = '/Users/hengdahe/Dropbox/LAB_2021/Linbi/Scripts_share/';

    subjects = {'180607_Sub11','180621_Sub18','180724_Sub23','180828_Sub32' ...
    ,'180608_Sub12','180622_Sub19','180724_Sub24','180829_Sub33' ...
    ,'180612_Sub14','180623_Sub20','180725_Sub25','180830_Sub34' ...
    ,'180614_Sub15','180624_Sub21','180807_Sub29','180830_Sub35' ...
    ,'180618_Sub17','180626_Sub22','180808_Sub30'}; % All

    h_before = zeros(length(subjects),1); 
    h_after = zeros(length(subjects),1); 
    Class_sub = zeros(length(subjects),1);

    for sub = 1:length(subjects)


        disp(['Subject - ',subjects{sub}])

        fileID = fopen([subdir,subjects{sub},'/',reg_foldername,'/',LC_foldername,'/',subjects{sub},'_LoacalMaxlog.txt'],'w');

        fprintf(fileID,subjects{sub});
        fprintf(fileID,'\n');

        %% load images
        disp('load images')

        % TSE image in Struct space
        nii_st = load_untouch_nii([subdir,subjects{sub},'/',reg_foldername,'/TSE2structhead.nii.gz']); 
        TSEinT1 = double(nii_st.img);

        % LC mask in Struct space
        nii_st = load_untouch_nii([subdir,subjects{sub}, ...
            '/',reg_foldername,'/',LC_foldername,'/LC_1SD_BINARY_TEMPLATE_StructSpace.nii.gz']); 
        LC1SDinT1 = double(nii_st.img);
        LC1SDinT1hdr = nii_st.hdr;

        nii_st = load_untouch_nii([subdir,subjects{sub}, ...
            '/',reg_foldername,'/',LC_foldername,'/LC_2SD_BINARY_TEMPLATE_StructSpace.nii.gz']); 
        LC2SDinT1 = double(nii_st.img);

        %% dilation of LC2SD
        disp('dilation of LC2SD')

        se = strel('sphere',1);
        LC2SDinT1_dil = imdilate(LC2SDinT1,se);

        %% Evaluation Criteria (before moving to local maxima)
        allvalues = TSEinT1(find(LC2SDinT1_dil));
        regionmean = mean(allvalues);
        regionstd = std(allvalues);
        Iin1SD = (TSEinT1(find(LC1SDinT1))-regionmean)/regionstd;
        Iin2SD = (TSEinT1(find(LC2SDinT1-LC1SDinT1))-regionmean)/regionstd;
        Iinbackground = (TSEinT1(find(LC2SDinT1_dil-LC2SDinT1))-regionmean)/regionstd; % background = dilated 2SD mask
        [h,p,ci,stats] = ttest2(Iin1SD,Iin2SD);

        h_before(sub) = h;
        fprintf(fileID,['T-test(Intensities in 1SD,Neighboring Intensities in 2SD): h = '...
            ,num2str(h),'; t = ',num2str(stats.tstat),'; p = ',num2str(p)]);

        %% moving 1SD mask to local maxima

        iterations = 1;

        for iter = 1:iterations
            ind = find(LC1SDinT1); 
            [row,col,pag] = ind2sub(size(LC1SDinT1),ind);
            LC1SDinT1_new = zeros(size(LC1SDinT1));
            for n = 1:length(row)

                region = zeros(size(LC1SDinT1));
                region(row(n),col(n),pag(n)) = 1;
                se = strel('sphere',1);
                region_neighbor = imdilate(region,se);
                % intersect of neighrbor and search area (LC2SDinT1)
                region_neighbor = region_neighbor&LC2SDinT1;
                % find max location in n_I and neighborhood
                [i j k] = ind2sub(size(region_neighbor),find(region_neighbor));
                [regmax regmaxidx] = sort(TSEinT1(region_neighbor),'descend');
                regmaxidx = regmaxidx(1);
                n_I = TSEinT1(row(n),col(n),pag(n));
                n_I_new = TSEinT1(i(regmaxidx),j(regmaxidx),k(regmaxidx));

                % modify 1SD mask
                LC1SDinT1_new(i(regmaxidx),j(regmaxidx),k(regmaxidx))=1;

            end
            LC1SDinT1 = LC1SDinT1_new;
        end

        % Evaluation Criteria (before moving to local maxima)
        allvalues = TSEinT1(find(LC2SDinT1_dil));
        regionmean = mean(allvalues);
        regionstd = std(allvalues);
        Iin1SD = (TSEinT1(find(LC1SDinT1))-regionmean)/regionstd;
        Iin2SD = (TSEinT1(find(LC2SDinT1-LC1SDinT1))-regionmean)/regionstd;
        Iinbackground = (TSEinT1(find(LC2SDinT1_dil-LC2SDinT1))-regionmean)/regionstd; % background = dilated 2SD mask
        [h,p,ci,stats] = ttest2(Iin1SD,Iin2SD);

        h_after(sub) = h;
        fprintf(fileID,'\n');
        fprintf(fileID,['After LocalMax T-test(Intensities in 1SD,Neighboring Intensities in 2SD): h = '...
            ,num2str(h),'; t = ',num2str(stats.tstat),'; p = ',num2str(p)]);

        fclose(fileID);
        %% class
        if h_before(sub)==1 % class 1, LC in 1 SD
            Class_sub(sub) = 1;
        elseif h_after(sub)==1 % class 2, LC in 2SD
               Class_sub(sub) = 2;
        else
            Class_sub(sub) = 3; % class 3, use LC template
        end

    end

    fileID = fopen([scriptdir,'Subject_Class1_LCin1SD.txt'],'w');
    sub_class = subjects(find(Class_sub==1));
    for i = 1:length(sub_class)
        fprintf(fileID,sub_class{i});
        fprintf(fileID,'\n');
    end
    fclose(fileID);

    fileID = fopen([scriptdir,'Subject_Class2_LCin2SD.txt'],'w');
    sub_class = subjects(find(Class_sub==2));
    for i = 1:length(sub_class)
        fprintf(fileID,sub_class{i});
        fprintf(fileID,'\n');
    end
    fclose(fileID);

    fileID = fopen([scriptdir,'Subject_Class3_LCinAtlas.txt'],'w');
    sub_class = subjects(find(Class_sub==3));
    for i = 1:length(sub_class)
        fprintf(fileID,sub_class{i});
        fprintf(fileID,'\n');
    end
    fclose(fileID);

end


