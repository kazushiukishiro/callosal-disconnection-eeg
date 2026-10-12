function [J,W,C] = cc_join_clinical_inputs(W,E,C)
%CC_JOIN_CLINICAL_INPUTS New public adapter; requires pseudonymous keys.
% W is primary regional WTC: CaseNo, State, Region, Value.
% E is exact-time: CaseNo, State, ConnectionType, MeanWTC.
% C has CaseNo and documented numeric clinical columns (already eligible
% outcomes; NaN for missing/inapplicable outcomes). No eligibility inferred.
% Input checks reject duplicates and invalid codes; no recoding or imputation.
assert(istable(W)&&istable(E)&&istable(C),'CCClinical:Table','Tables required.');
cols={'CaseNo','AgeOnset','AgeSurgery','Duration','Sex', ...
    'MRIAbnormality','MRILaterality','OverallOutcome','DropOutcome'};
assert(all(ismember(cols,C.Properties.VariableNames)), ...
    'CCClinical:Columns','Clinical schema incomplete.');
assert(all(ismember({'CaseNo','State','Region','Value'},W.Properties.VariableNames))&& ...
    all(ismember({'CaseNo','State','ConnectionType','MeanWTC'},E.Properties.VariableNames)), ...
    'CCClinical:Columns','Connectivity schema incomplete.');
W.CaseNo=key(W.CaseNo);E.CaseNo=key(E.CaseNo);C.CaseNo=key(C.CaseNo);
assert(numel(unique(C.CaseNo))==height(C),'CCClinical:Duplicate', ...
    'Clinical keys are duplicated; join would inflate observations.');
for k=2:numel(cols)
    a=C.(cols{k});
    assert(isnumeric(a)&&isreal(a)&&iscolumn(a)&&~any(isinf(a)), ...
        'CCClinical:Numeric','Clinical columns must be real numeric, without Inf.');
end
for name={'AgeOnset','AgeSurgery','Duration'}
    a=C.(name{1});
    assert(all(a(isfinite(a))>=0),'CCClinical:Age','Negative age/duration.');
end
for name={'Sex','MRIAbnormality'}
    a=C.(name{1});
    assert(all(ismember(a(isfinite(a)),[0 1])),'CCClinical:BinaryCode', ...
        'Binary fields must use 0/1/NaN; do not infer another coding.');
end
a=C.MRILaterality;
assert(all(ismember(a(isfinite(a)),[0 1 2])),'CCClinical:LateralityCode', ...
    'Laterality must use 0/1/2/NaN.');
q=isfinite(C.MRIAbnormality)&isfinite(C.MRILaterality);
assert(all(C.MRIAbnormality(q)==double(C.MRILaterality(q)~=0)), ...
    'CCClinical:MRICoding','Inconsistent MRI codes; review rather than recode.');
for name={'OverallOutcome','DropOutcome'}
    a=C.(name{1});
    assert(all(ismember(a(isfinite(a)),1:5)),'CCClinical:OutcomeCode', ...
        'Outcome grades must be 1-5 or NaN, with higher grades worse.');
end
% Keep all five source-specific measures, not a merged Pre/Post alias.
M=cc_connectivity_change_sources(W,E);
J=innerjoin(M,C(:,cols),'Keys','CaseNo');
assert(numel(unique(J.CaseNo))==height(J),'CCClinical:Duplicate','Join inflated IDs.');
assert(~isempty(J),'CCClinical:EmptyJoin','No matching clinical/EEG keys.');
% Model path is primary-only; do not require availability in exact-time.
cv=C(:,{'CaseNo','AgeOnset','AgeSurgery','Duration'});
W=innerjoin(W,cv,'Keys','CaseNo');
assert(~isempty(W),'CCClinical:EmptyJoin','No primary/clinical match.');
assert(isnumeric(W.Value)&&isreal(W.Value)&&iscolumn(W.Value), ...
    'CCClinical:Numeric','Primary Value must be numeric.');
assert(all(isnan(W.Value)|(isfinite(W.Value)&W.Value>=0&W.Value<=1)), ...
    'CCClinical:WTC','WTC must be in [0,1] or NaN.');
W.mean_MeanWTC_4_13=W.Value;
W.State=categorical(string(W.State),{'Pre','Anterior','Posterior','Post'});
W.Region=categorical(string(W.Region),{'CP','FT','PO','T','TO'});
assert(~any(isundefined(W.State))&&~any(isundefined(W.Region)), ...
    'CCClinical:Categories','Unrecognized state or region.');
W.CaseNo=categorical(W.CaseNo);
% CaseNum is only an ID used to deduplicate covariates in the source code.
W.CaseNum=string(W.CaseNo);
end

function s=key(x)
s=strtrim(string(x));
assert(iscolumn(s)&&all(~ismissing(s)&strlength(s)>0), ...
    'CCClinical:Key','Nonmissing column keys required.');
end
