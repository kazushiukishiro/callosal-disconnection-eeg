function R = cc_modifier_reference_blocks(W)
%CC_MODIFIER_REFERENCE_BLOCKS Numerical blocks extracted from supplied source.
% Test reference only. Input is already-joined artificial regional table.
% No study I/O, paths, identifier lists, or expected clinical results.
% Source: run_FINAL_QC_clean_effect_modifiers.m; spans documented in docs.
warnRows=cell(0,4);
% Original source lines 50-62.
% centered variables
W.AgeOnset_c = W.AgeOnset - mean(W.AgeOnset,'omitnan');
W.AgeSurgery_c = W.AgeSurgery - mean(W.AgeSurgery,'omitnan');
W.Duration_c = W.Duration - mean(W.Duration,'omitnan');

% standardized variables
W.AgeOnset_z = ...
    (W.AgeOnset - mean(W.AgeOnset,'omitnan')) ./ ...
    std(W.AgeOnset,'omitnan');

W.Duration_z = ...
    (W.Duration - mean(W.Duration,'omitnan')) ./ ...
    std(W.Duration,'omitnan');

% Original source lines 77-80.
lastwarn('','');
mOnset = fitlme( ...
    W, ...
    ['mean_MeanWTC_4_13 ~ State*AgeOnset_c + Region + ' ...
     '(1|CaseNo) + (1|CaseNo:Region)']);

% Original source lines 86-86.
Aonset = anova(mOnset,'DFMethod','satterthwaite');
[wm,wi]=lastwarn;warnRows(end+1,:)={"AgeOnset",~isempty(wm),string(wi),string(wm)};

% Original source lines 94-97.
lastwarn('','');
mSurgery = fitlme( ...
    W, ...
    ['mean_MeanWTC_4_13 ~ State*AgeSurgery_c + Region + ' ...
     '(1|CaseNo) + (1|CaseNo:Region)']);

% Original source lines 103-103.
Asurgery = anova(mSurgery,'DFMethod','satterthwaite');
[wm,wi]=lastwarn;warnRows(end+1,:)={"AgeSurgery",~isempty(wm),string(wi),string(wm)};

% Original source lines 111-114.
lastwarn('','');
mDuration = fitlme( ...
    W, ...
    ['mean_MeanWTC_4_13 ~ State*Duration_c + Region + ' ...
     '(1|CaseNo) + (1|CaseNo:Region)']);

% Original source lines 120-120.
Aduration = anova(mDuration,'DFMethod','satterthwaite');
[wm,wi]=lastwarn;warnRows(end+1,:)={"Duration",~isempty(wm),string(wi),string(wm)};

% Original source lines 128-132.
lastwarn('','');
mJoint = fitlme( ...
    W, ...
    ['mean_MeanWTC_4_13 ~ ' ...
     'State*AgeOnset_c + State*Duration_c + Region + ' ...
     '(1|CaseNo) + (1|CaseNo:Region)']);

% Original source lines 138-138.
Ajoint = anova(mJoint,'DFMethod','satterthwaite');
[wm,wi]=lastwarn;warnRows(end+1,:)={"Joint",~isempty(wm),string(wi),string(wm)};

% Original source lines 146-150.
lastwarn('','');
mJointZ = fitlme( ...
    W, ...
    ['mean_MeanWTC_4_13 ~ ' ...
     'State*AgeOnset_z + State*Duration_z + Region + ' ...
     '(1|CaseNo) + (1|CaseNo:Region)']);

% Original source lines 156-156.
AjointZ = anova(mJointZ,'DFMethod','satterthwaite');
[wm,wi]=lastwarn;warnRows(end+1,:)={"JointZ",~isempty(wm),string(wi),string(wm)};

% Original source lines 164-173.
patientCov = unique( ...
    W(:,{'CaseNum','AgeOnset','AgeSurgery','Duration'}), ...
    'rows');

X = [ ...
    patientCov.AgeOnset, ...
    patientCov.AgeSurgery, ...
    patientCov.Duration];

[Rho,Pcorr] = corr(X,'Type','Spearman','Rows','pairwise');

R=struct;
R.Warnings=cell2table(warnRows,'VariableNames', ...
    {'Model','WarningOccurred','WarningIdentifier','WarningMessage'});
R.ModelData=W;R.Models={mOnset;mSurgery;mDuration;mJoint;mJointZ};
R.ANOVAs={Aonset;Asurgery;Aduration;Ajoint;AjointZ};
R.CovariateRho=Rho;R.CovariateP=Pcorr;
end
