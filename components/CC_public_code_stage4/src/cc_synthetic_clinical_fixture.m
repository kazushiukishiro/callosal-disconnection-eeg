function F = cc_synthetic_clinical_fixture()
%CC_SYNTHETIC_CLINICAL_FIXTURE Fresh artificial covariates, no patient input.
% Uses stage-2's unchanged arbitrary regional/epoch fixture only to exercise
% interfaces. It does NOT consume or rerun stage-1 EDF processing.
oldRng=rng;restore=onCleanup(@() rng(oldRng)); %#ok<NASGU>
base=cc_synthetic_group_fixture();
P=cc_public_group_ops('select_primary',base.Epochs,base.Rules);
bad=P.CaseNo==base.ExcludedGroup.CaseNo & ...
    P.State==base.ExcludedGroup.State & P.Region==base.ExcludedGroup.Region;
P=P(~bad,:);
V=cc_public_group_ops('value_epochs',P,'MeanWTC_4_13');
[W,~,~]=cc_public_group_ops('summarize',V,'WTC','Matched');
W=W(:,{'CaseNo','State','Region','Value'});
ids=union(string(W.CaseNo),string(base.Exact.CaseNo));n=numel(ids);
rng(130363,'twister');
AgeOnset=round(10*rand(n,1))/2;
Duration=2+round(100*rand(n,1))/10;
AgeSurgery=AgeOnset+Duration;
Sex=mod((1:n)',2);MRILaterality=mod((0:n-1)',3);
MRIAbnormality=double(MRILaterality~=0);
OverallOutcome=mod((0:n-1)',5)+1;
DropOutcome=mod(2*(0:n-1)',5)+1;
% Arbitrary incomplete covariates/outcomes; NOT the study's missingness.
AgeOnset(4)=NaN;Duration(7)=NaN;Sex(8)=NaN;
MRIAbnormality(6)=NaN;MRILaterality(9)=NaN;
OverallOutcome([2 5 10])=NaN;DropOutcome([1 2 5 8 10])=NaN;
C=table(ids,AgeOnset,AgeSurgery,Duration,Sex,MRIAbnormality, ...
    MRILaterality,OverallOutcome,DropOutcome,'VariableNames', ...
    {'CaseNo','AgeOnset','AgeSurgery','Duration','Sex','MRIAbnormality', ...
    'MRILaterality','OverallOutcome','DropOutcome'});
C=C(randperm(n),:); % join must use keys rather than input row positions
F=struct('Primary',W,'Exact',base.Exact,'Clinical',C);
end
