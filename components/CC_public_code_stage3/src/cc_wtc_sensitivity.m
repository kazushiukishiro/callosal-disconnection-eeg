function varargout = cc_wtc_sensitivity(action,varargin)
%CC_WTC_SENSITIVITY New public wrappers for documented WTC sensitivities.
% Not an unchanged historical script or a final-cohort assembly command.
% All inputs are explicit tables; this function never reads/writes files.
% Real-data callers must supply their own QC-clean inputs. No clinical
% exclusion identities or expected clinical results are embedded here.
%
% [L,C] = cc_wtc_sensitivity('loo',W,X)
% B = cc_wtc_sensitivity('bootstrap',W,X,nResamples,seed)
% G = cc_wtc_sensitivity('logit',W)
% [Wb,Xb] = cc_wtc_sensitivity('resample',W,X,sampledCases)
% [z,info] = cc_wtc_sensitivity('logit_values',y)
%
% W: CaseNo, State, Region, mean_MeanWTC_4_13 (one row per key).
% X: CaseNo, State, ConnectionType, MeanWTC (one row per key).
% States: Pre,Anterior,Posterior,Post. Regions: CP,FT,PO,T,TO.
% X must contain paired Intra/Inter estimates for each included case/state.
% No missing/nonfinite values are silently dropped by this wrapper.
% See docs/SOURCE_PROVENANCE.md for retained logic and changed packaging.

switch char(action)
    case 'loo'
        W=prepareTable(varargin{1},'regional');
        X=prepareTable(varargin{2},'exact');
        [varargout{1},varargout{2}]=runLOO(W,X);
    case 'bootstrap'
        W=prepareTable(varargin{1},'regional');
        X=prepareTable(varargin{2},'exact');
        nResamples=2000;
        seed=20260820;
        if numel(varargin)>=3, nResamples=varargin{3}; end
        if numel(varargin)>=4, seed=varargin{4}; end
        validateattributes(nResamples,{'numeric'}, ...
            {'scalar','integer','finite','>=',2});
        validateattributes(seed,{'numeric'}, ...
            {'scalar','integer','finite','nonnegative','<=',2^32-1});
        varargout{1}=runBootstrap(W,X,nResamples,seed);
    case 'logit'
        W=prepareTable(varargin{1},'regional');
        % This later history block explicitly used FT as region reference.
        W.Region=categorical(string(W.Region),{'FT','T','TO','CP','PO'});
        [W.LogitWTC,info]=transformLogit(W.mean_MeanWTC_4_13);
        oldWarning=warningState();
        cleanup=onCleanup(@() restoreLastWarning(oldWarning)); %#ok<NASGU>
        lastwarn('');
        m=fitlme(W,['LogitWTC ~ State + Region + ' ...
            '(1|CaseNo) + (1|CaseNo:Region)'],'FitMethod','ML');
        A=anova(m,'DFMethod','satterthwaite');
        [warnMessage,warnID]=lastwarn;
        S=termTable(m,A,'State','LogitPrimary','',height(W), ...
            numel(unique(string(W.CaseNo))),warnMessage,warnID);
        C=coefficientTable(m,'LogitPrimary','');
        varargout{1}=struct('Summary',S,'Coefficients',C, ...
            'BoundaryHandling',info,'TransformedValues',W.LogitWTC);
    case 'resample'
        W=prepareTable(varargin{1},'regional');
        X=prepareTable(varargin{2},'exact');
        [varargout{1},varargout{2}]=resampleTables(W,X,varargin{3});
    case 'logit_values'
        [varargout{1},varargout{2}]=transformLogit(varargin{1});
    otherwise
        error('CCWtcSensitivity:Action','Unknown action.');
end
end

function T=prepareTable(T,kind)
if ~istable(T)
    error('CCWtcSensitivity:Input','Expected a MATLAB table.');
end
if strcmp(kind,'regional')
    keys={'CaseNo','State','Region'};
    valueName='mean_MeanWTC_4_13';
    allowed={'CP','FT','PO','T','TO'};
else
    keys={'CaseNo','State','ConnectionType'};
    valueName='MeanWTC';
    allowed={'Intra','Inter'};
end
required=[keys,{valueName}];
if ~all(ismember(required,T.Properties.VariableNames))
    error('CCWtcSensitivity:Columns','Required input columns are missing.');
end
T=T(:,required);
if isempty(T)
    error('CCWtcSensitivity:Empty','Input table is empty.');
end
for j=1:numel(keys)
    v=strip(string(T.(keys{j})));
    if ~iscolumn(v) || any(ismissing(v) | v=='' | contains(v,'|'))
        error('CCWtcSensitivity:Key','Missing/invalid grouping identifier.');
    end
    T.(keys{j})=v;
end
states={'Pre','Anterior','Posterior','Post'};
if any(~ismember(T.State,string(states))) || ...
        any(~ismember(T.(keys{3}),string(allowed)))
    error('CCWtcSensitivity:Levels','Unexpected grouping level.');
end
if height(unique(T(:,keys),'rows'))~=height(T)
    error('CCWtcSensitivity:Duplicate','Duplicate observation key.');
end
y=T.(valueName);
if ~isnumeric(y) || ~isreal(y) || ~iscolumn(y) || ...
        any(~isfinite(y)) || any(y<0 | y>1)
    error('CCWtcSensitivity:WTC','WTC must be finite and in [0,1].');
end
if ~all(ismember(string(states),unique(T.State))) || ...
        ~all(ismember(string(allowed),unique(T.(keys{3}))))
    error('CCWtcSensitivity:Levels','At least one required level is absent.');
end
if numel(unique(T.CaseNo))<3
    error('CCWtcSensitivity:CaseCount','At least three distinct cases required.');
end
if strcmp(kind,'exact')
    g=findgroups(T.CaseNo,T.State);
    if any(splitapply(@numel,T.MeanWTC,g)~=2)
        error('CCWtcSensitivity:Pair','An exact-time state lacks an Inter/Intra pair.');
    end
end
T.CaseNo=categorical(T.CaseNo);
T.State=categorical(T.State,states);
T.(keys{3})=categorical(T.(keys{3}),allowed);
end

function [S,C]=runLOO(W,X)
S=table;
C=table;
oldWarning=warningState();
cleanup=onCleanup(@() restoreLastWarning(oldWarning)); %#ok<NASGU>
wc=categories(removecats(W.CaseNo));
xc=categories(removecats(X.CaseNo));
for i=1:numel(wc)
    fprintf('WTC LOO %d/%d\n',i,numel(wc));
    T=W(string(W.CaseNo)~=string(wc{i}),:);
    T.CaseNo=removecats(T.CaseNo);
    formulas={ ...
        ['mean_MeanWTC_4_13 ~ State + Region + ' ...
         '(1|CaseNo) + (1|CaseNo:Region)'], ...
        ['mean_MeanWTC_4_13 ~ State*Region + ' ...
         '(1|CaseNo) + (1|CaseNo:Region)']};
    labels={'Primary','Region'};
    terms={'State','State:Region'};
    for j=1:2
        lastwarn('');
        m=fitlme(T,formulas{j},'FitMethod','ML');
        A=anova(m,'DFMethod','satterthwaite');
        [wm,wi]=lastwarn;
        q=termTable(m,A,terms{j},labels{j},wc{i},height(T), ...
            numel(unique(string(T.CaseNo))),wm,wi);
        S=appendRows(S,q);
        C=appendRows(C,coefficientTable(m,labels{j},wc{i}));
    end
end
for i=1:numel(xc)
    fprintf('Exact-time LOO %d/%d\n',i,numel(xc));
    T=X(string(X.CaseNo)~=string(xc{i}),:);
    T.CaseNo=removecats(T.CaseNo);
    lastwarn('');
    m=fitlme(T,'MeanWTC ~ State*ConnectionType + (1|CaseNo)', ...
        'FitMethod','ML');
    A=anova(m,'DFMethod','satterthwaite');
    [wm,wi]=lastwarn;
    S=appendRows(S,termTable(m,A,'State:ConnectionType','Exact', ...
        xc{i},height(T),numel(unique(string(T.CaseNo))),wm,wi));
    C=appendRows(C,coefficientTable(m,'Exact',xc{i}));
end
end

function out=runBootstrap(W,X,B,seed)
% Resample complete patient clusters, sharing draws across the two models.
% Repeated draws get new cluster IDs; no within-patient observations sampled.
wc=categories(removecats(W.CaseNo));
xc=categories(removecats(X.CaseNo));
if ~isequal(sort(string(wc)),sort(string(xc)))
    error('CCWtcSensitivity:BootstrapCaseSet', ...
        'Shared-draw bootstrap requires the same case set in both inputs.');
end
n=numel(wc);
oldRng=rng;
restoreRng=onCleanup(@() rng(oldRng)); %#ok<NASGU>
oldWarning=warningState();
restoreWarning=onCleanup(@() restoreLastWarning(oldWarning)); %#ok<NASGU>
rng(seed,'twister');
baseFormulas={ ...
    ['mean_MeanWTC_4_13 ~ State + Region + ' ...
     '(1|CaseNo) + (1|CaseNo:Region)'], ...
    'MeanWTC ~ State*ConnectionType + (1|CaseNo)'};
bootFormulas={ ...
    ['mean_MeanWTC_4_13 ~ State + Region + ' ...
     '(1|BootCase) + (1|BootCaseRegion)'], ...
    'MeanWTC ~ State*ConnectionType + (1|BootCase)'};
labels={'Primary','Exact'};
orig=nan(2,3);
coefTables=table;
baseWarnings=cell(0,4);
inputs={W,X};
for j=1:2
    lastwarn('');
    m=fitlme(inputs{j},baseFormulas{j},'FitMethod','ML');
    orig(j,:)=targetEstimates(m,labels{j});
    coefTables=appendRows(coefTables,coefficientTable(m,labels{j},''));
    [wm,wi]=lastwarn;
    baseWarnings(end+1,:)={labels{j},~isempty(wm),wi,wm}; %#ok<AGROW>
end
primaryDraws=nan(B,3);
exactDraws=nan(B,3);
sampleIndices=zeros(n,B);
fitRows=cell(0,7);
for b=1:B
    if b==1 || mod(b,10)==0 || b==B
        fprintf('Patient-cluster bootstrap %d/%d (synthetic test when called by demo)\n',b,B);
    end
    idx=randi(n,n,1);
    sampleIndices(:,b)=idx;
    [Tb,Xb]=resampleTables(W,X,wc(idx));
    bootInputs={Tb,Xb};
    for j=1:2
        lastwarn('');
        failed=false;
        errID='';
        message='';
        estimates=nan(1,3);
        try
            mb=fitlme(bootInputs{j},bootFormulas{j},'FitMethod','ML');
            estimates=targetEstimates(mb,labels{j});
            if any(~isfinite(estimates))
                error('CCWtcSensitivity:BootstrapFinite','Nonfinite coefficient.');
            end
        catch ME
            failed=true;
            errID=ME.identifier;
            message=ME.message;
        end
        [wm,wi]=lastwarn;
        if j==1, primaryDraws(b,:)=estimates; else, exactDraws(b,:)=estimates; end
        fitRows(end+1,:)={b,labels{j},~failed,errID,message,wi,wm}; %#ok<AGROW>
    end
end
fitStatus=cell2table(fitRows,'VariableNames', ...
    {'Replicate','Model','Succeeded','ErrorIdentifier','ErrorMessage', ...
     'WarningIdentifier','WarningMessage'});
summaryRows=cell(0,9);
draws={primaryDraws,exactDraws};
contrastLabels={'Anterior vs Pre','Posterior vs Pre','Post vs Pre'; ...
    'Anterior x Inter','Posterior x Inter','Post x Inter'};
for j=1:2
    A=draws{j};
    ok=all(isfinite(A),2);
    nGood=nnz(ok);
    for k=1:3
        ci=[NaN NaN];
        prop=NaN;
        if nGood>=2
            ci=prctile(A(ok,k),[2.5 97.5]);
            prop=mean(A(ok,k)<0);
        end
        summaryRows(end+1,:)={labels{j},contrastLabels{j,k},orig(j,k), ...
            B,nGood,B-nGood,ci(1),ci(2),prop}; %#ok<AGROW>
    end
end
out=struct;
out.Summary=cell2table(summaryRows,'VariableNames', ...
    {'Model','Contrast','Estimate','RequestedReplicates','SuccessfulReplicates', ...
     'FailedReplicates','CI_Lower','CI_Upper','ProportionNegative'});
out.PrimaryDraws=primaryDraws;
out.ExactDraws=exactDraws;
out.SampleIndices=sampleIndices;
out.CaseOrder=string(wc);
out.FitStatus=fitStatus;
out.BaselineCoefficients=coefTables;
out.BaselineWarnings=cell2table(baseWarnings,'VariableNames', ...
    {'Model','WarningOccurred','WarningIdentifier','WarningMessage'});
out.Replicates=B;
out.Seed=seed;
end

function [Wb,Xb]=resampleTables(W,X,sampledCases)
% Original cluster-ID construction is retained; no alternate resampling unit.
ids=strip(string(sampledCases(:)));
availW=unique(string(W.CaseNo));
availX=unique(string(X.CaseNo));
if isempty(ids) || any(ismissing(ids)) || ...
        any(~ismember(ids,availW)) || any(~ismember(ids,availX))
    error('CCWtcSensitivity:Draw','Invalid sampled case list.');
end
ww=cell(numel(ids),1);
xx=cell(numel(ids),1);
for j=1:numel(ids)
    q=W(string(W.CaseNo)==ids(j),:);
    q.BootCase=categorical(repmat("B"+string(j),height(q),1));
    q.BootCaseRegion=categorical(string(q.BootCase)+"_"+string(q.Region));
    ww{j}=q;
    q=X(string(X.CaseNo)==ids(j),:);
    q.BootCase=categorical(repmat("B"+string(j),height(q),1));
    xx{j}=q;
end
Wb=vertcat(ww{:});
Xb=vertcat(xx{:});
end

function [z,info]=transformLogit(y)
if ~isnumeric(y) || ~isreal(y) || ~iscolumn(y) || isempty(y) || ...
        any(~isfinite(y)) || any(y<0 | y>1)
    error('CCWtcSensitivity:LogitInput','Expected finite WTC in [0,1].');
end
% Exact bound used in the later QC-clean history block, not a new threshold.
epsVal=1e-6;
nLow=sum(y<=epsVal);
nHigh=sum(y>=1-epsVal);
yBound=min(max(y,epsVal),1-epsVal);
z=log(yBound./(1-yBound));
info=struct('Epsilon',epsVal,'AtOrBelowLowerBound',nLow, ...
    'AtOrAboveUpperBound',nHigh,'NumericallyChanged',nnz(yBound~=y));
end

function T=termTable(m,A,term,label,excluded,nObs,nCases,wm,wi)
i=find(string(A.Term)==string(term));
if numel(i)~=1
    error('CCWtcSensitivity:Term','Expected model term not found uniquely.');
end
v=[A.FStat(i),A.DF1(i),A.DF2(i),A.pValue(i)];
if any(~isfinite(v)) || v(1)<0 || any(v(2:3)<=0) || v(4)<0 || v(4)>1
    error('CCWtcSensitivity:Inference','Invalid omnibus inference output.');
end
if m.NumObservations~=nObs
    error('CCWtcSensitivity:Observations','Model silently dropped observations.');
end
T=table(string(label),string(excluded),string(term),nCases,nObs, ...
    v(1),v(2),v(3),v(4),string('ML'),string('Satterthwaite'), ...
    ~isempty(wm),string(wi),string(wm),'VariableNames', ...
    {'Model','ExcludedCase','Term','N_Cases','N_Observations','FStat','DF1', ...
     'DF2','P_Unadjusted','FitMethod','DFMethod','WarningOccurred', ...
     'WarningIdentifier','WarningMessage'});
end

function T=coefficientTable(m,label,excluded)
C=m.Coefficients;
n=numel(C.Estimate);
if any(~isfinite(C.Estimate)) || any(~isfinite(C.SE)) || ...
        any(C.DF~=m.NumObservations-n)
    error('CCWtcSensitivity:Coefficients','Invalid Residual coefficient output.');
end
T=table(repmat(string(label),n,1),repmat(string(excluded),n,1), ...
    string(C.Name),C.Estimate,C.SE,C.tStat,C.DF,C.pValue,C.Lower,C.Upper, ...
    repmat(string('Residual'),n,1),'VariableNames', ...
    {'Model','ExcludedCase','Term','Estimate','SE','tStat','DF','P_Unadjusted', ...
     'CI_Lower','CI_Upper','DFMethod'});
end

function e=targetEstimates(m,label)
C=m.Coefficients;
names=["State_Anterior","State_Posterior","State_Post"];
if strcmp(label,'Exact'), names=names+":ConnectionType_Inter"; end
e=nan(1,3);
for k=1:3
    hit=find(string(C.Name)==names(k));
    if numel(hit)~=1
        error('CCWtcSensitivity:Coefficient','Required coefficient not unique.');
    end
    e(k)=C.Estimate(hit);
end
end

function T=appendRows(T,Q)
if isempty(T), T=Q; else, T=[T;Q]; end
end

function s=warningState()
[s.message,s.identifier]=lastwarn;
end

function restoreLastWarning(s)
lastwarn(s.message,s.identifier);
end
