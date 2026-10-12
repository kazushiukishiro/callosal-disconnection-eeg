function varargout = cc_public_group_ops(action,varargin)
%CC_PUBLIC_GROUP_OPS Public interface to retained numeric helper functions.
% NEW packaging interface; it does not load clinical files or model objects.
% Local helpers below are exact extracts of the saved post hoc analysis code.
% See docs/SOURCE_PROVENANCE.md for extraction hashes and limitations.
% Caller supplies candidate epoch tables and explicit exclusion decisions.
% This function does not infer clinical exclusions from WTC thresholds.

switch char(action)
    case 'select_primary'
        E=canonicalEpochs(varargin{1}); rules=varargin{2};
        requireColumns(E,{'RegionBad','MeanWTC_4_13'});
        assert(all(ismember(double(E.RegionBad),[0 1])), ...
            'CCPublic:QCFlag','RegionBad must contain only zero or one.');
        for nm={'PreMin','PostMin','PostMax'}
            validateattributes(rules.(nm{1}),{'numeric'}, ...
                {'scalar','integer','positive','finite'});
        end
        assert(rules.PostMax>=rules.PostMin,'CCPublic:Rules','Invalid Post limits.');
        varargout{1}=selectPrimary(E,rules);
    case 'value_epochs'
        E=canonicalEpochs(varargin{1});
        varargout{1}=valueEpochs(E,varargin{2});
    case 'match'
        P=canonicalEpochs(varargin{1}); T=canonicalEpochs(varargin{2});
        requireNumeric(T,'Value');
        varargout{1}=alignToPrimary(P,T,varargin{3});
    case 'summarize'
        E=canonicalEpochs(varargin{1}); requireNumeric(E,'Value');
        V=groupedValues(E,'Value'); Q=patientValues(V);
        varargout={V,Q,describeValues(Q,E,V,varargin{2},varargin{3})};
    case 'model_table'
        varargout{1}=modelTable(varargin{1});
    case 'omnibus'
        varargout{1}=omnibusTable(varargin{1},varargin{2},varargin{3});
    case 'contrasts'
        varargout{1}=lmmContrasts(varargin{1},varargin{2},varargin{3});
    case 'bootstrap_dwpli'
        % The retained helper's output label explicitly says 10000.
        % Do not offer a different replicate count under that label.
        savedRng=rng; restoreRng=onCleanup(@() rng(savedRng)); %#ok<NASGU>
        varargout{1}=bootstrapContrasts(varargin{1},varargin{2},10000);
    case 'keys'
        varargout{1}=epochKey(canonicalEpochs(varargin{1}));
    otherwise
        error('CCPublic:Action','Unknown action: %s',char(action));
end
end

function Q = valueEpochs(T,col)
requireNumeric(T,col);
Q = T(:,{'CaseNo','State','Region','StartSec'});
Q.Value = T.(col);
end

function Q = alignToPrimary(P,T,label)
[hit,loc] = ismember(epochKey(P),epochKey(T));
if ~all(hit)
    error('CCMatched:MissingKey', ...
        '%s lacks %d primary-selected epoch keys; the set was not reduced.', ...
        label,nnz(~hit));
end
Q = T(loc,:);
if any(~isfinite(Q.Value))
    error('CCMatched:Nonfinite', ...
        '%s has nonfinite matched values; the set was not reduced.',label);
end
assert(isequal(epochKey(P),epochKey(Q)),'CCMatched:Order','Matched key order failed.');
end

function Q = patientValues(V)
[g,c,s] = findgroups(V.CaseNo,V.State);
x = splitapply(@(a) mean(a,'omitnan'),V.Value,g);
Q = table(c,s,x,'VariableNames',{'CaseNo','State','Value'});
end

function out = describeValues(Q,E,V,metric,selection)
pre = Q(Q.State=="Pre",{'CaseNo','Value'});
pre.Properties.VariableNames = {'CaseNo','PreValue'};
R = innerjoin(Q,pre,'Keys','CaseNo');
validPre = isfinite(R.PreValue) & R.PreValue>0;
% Zero/negative dwPLI Pre cannot support a percent ratio; raw/model/bootstrap
% analyses retain finite negative dwPLI values. Normalized dwPLI is not used.
R.Normalized = nan(height(R),1);
R.Normalized(validPre) = 100*R.Value(validPre)./R.PreValue(validPre);
if strcmp(metric,'dwPLI')
    R.Normalized(:) = NaN; % ratio is not part of the dwPLI analysis plan
end
states = ["Pre","Anterior","Posterior","Post"];
rows = cell(0,13);
for s=1:4
    a = Q.Value(Q.State==states(s)); a=a(isfinite(a));
    b = R.Normalized(R.State==states(s)); b=b(isfinite(b));
    [ma,sa,ea]=moments(a); [mb,sb,eb]=moments(b);
    rows(end+1,:)={selection,metric,char(states(s)),numel(a),ma,sa,ea, ...
        numel(b),mb,sb,eb,nnz(V.State==states(s)), ...
        nnz(E.State==states(s)&isfinite(E.Value))}; %#ok<AGROW>
end
out=cell2table(rows,'VariableNames',{'Selection','Metric','State', ...
    'N_Raw','MeanRaw','SDRaw','SEMRaw','N_Normalized','MeanNormalized', ...
    'SDNormalized','SEMNormalized','RegionalGroups','FiniteEpochRegionRows'});
end

function [m,s,e]=moments(x)
m=NaN;s=NaN;e=NaN;
if ~isempty(x),m=mean(x);end
if numel(x)>=2,s=std(x);e=s/sqrt(numel(x));end
end

function V=modelTable(V)
V=V(isfinite(V.Value),{'CaseNo','State','Region','Value'});
V.CaseNo=categorical(V.CaseNo);
V.State=categorical(V.State,{'Pre','Anterior','Posterior','Post'});
V.Region=categorical(V.Region,{'CP','FT','PO','T','TO'});
end

function T=omnibusTable(m,label,n)
A=anova(m,'DFMethod','satterthwaite');
a=string(A.Term); nr=numel(a);
T=table(repmat(string(label),nr,1),a,A.FStat,A.DF1,A.DF2,A.pValue, ...
    repmat(n,nr,1),repmat("ML",nr,1),repmat("satterthwaite",nr,1), ...
    'VariableNames',{'Model','Term','FStat','DF1','DF2','P_Unadjusted', ...
    'N_RegionalObservations','FitMethod','DFMethod'});
end

function T=lmmContrasts(m,label,n)
C=m.Coefficients; names=string(C.Name); beta=C.Estimate;
I=zeros(1,3); target=["State_Anterior","State_Posterior","State_Post"];
for j=1:3
    q=find(names==target(j));
    if numel(q)~=1,error('CCMatched:Coefficient','Expected state coefficient missing.');end
    I(j)=q;
end
H=zeros(4,numel(beta));
H(1,I(1))=1;
H(2,I(2))=1;H(2,I(1))=-1;
H(3,I(3))=1;H(3,I(2))=-1;
H(4,I(3))=1;
labels={'Anterior minus Pre','Posterior minus Anterior', ...
    'Post minus Posterior','Post minus Pre'};
rows=cell(0,12);
for j=1:4
    est=H(j,:)*beta;
    se=sqrt(H(j,:)*m.CoefficientCovariance*H(j,:)');
    [p,~,~,df]=coefTest(m,H(j,:),0,'DFMethod','satterthwaite');
    if ~(isfinite(df)&&df>0&&isfinite(se)&&se>0)
        error('CCMatched:Contrast','Invalid contrast variance or degrees of freedom.');
    end
    bound=tinv(0.975,df)*se;
    rows(end+1,:)={label,'LMM_satterthwaite',labels{j},n,'regional observations', ...
        est,se,df,p,est-bound,est+bound,NaN}; %#ok<AGROW>
end
T=contrastTable(rows);
end

function T=bootstrapContrasts(Q,label,B)
earlier=["Pre","Anterior","Posterior","Pre"];
later=["Anterior","Posterior","Post","Post"];
labels={'Anterior minus Pre','Posterior minus Anterior', ...
    'Post minus Posterior','Post minus Pre'};
rows=cell(0,12);
for j=1:4
    a=Q(Q.State==earlier(j),{'CaseNo','Value'});
    b=Q(Q.State==later(j),{'CaseNo','Value'});
    a.Properties.VariableNames={'CaseNo','Earlier'};
    b.Properties.VariableNames={'CaseNo','Later'};
    J=innerjoin(a,b,'Keys','CaseNo'); x=J.Later-J.Earlier;
    x=x(isfinite(x));n=numel(x);
    if n<3,error('CCMatched:BootstrapN','Fewer than three paired patients.');end
    % Same fixed seed at the start of each contrast for both selections.
    rng(20260820+j,'twister');
    indices=randi(n,n,B);
    bm=mean(reshape(x(indices),n,B),1);
    ci=prctile(bm,[2.5 97.5]);
    rows(end+1,:)={label,'Paired_patient_bootstrap_10000',labels{j},n, ...
        'paired patients',mean(x),std(bm),NaN,NaN,ci(1),ci(2),mean(bm<0)}; %#ok<AGROW>
end
T=contrastTable(rows);
end

function T=contrastTable(rows)
T=cell2table(rows,'VariableNames',{'Model','Method','Contrast','N','N_Unit', ...
    'Estimate','SE','DF','P_Unadjusted','CI_Lower','CI_Upper','ProportionNegative'});
end

function T = canonicalEpochs(T)
requireColumns(T,{'CaseNo','State','Region','StartSec'});
T = canonicalGroups(T);
requireNumeric(T,'StartSec');
if any(~isfinite(T.StartSec)) || any(T.StartSec < 0)
    error('CCEpochAudit:Keys','Missing/invalid epoch start time.');
end
if numel(unique(epochKey(T))) ~= height(T)
    error('CCEpochAudit:DuplicateEpochs','Duplicate case/state/region/time keys.');
end
end

function T = canonicalGroups(T)
requireColumns(T,{'CaseNo','State','Region'});
for n = {'CaseNo','State','Region'}
    T.(n{1}) = strip(string(T.(n{1})));
    if any(ismissing(T.(n{1})) | T.(n{1}) == "")
        error('CCEpochAudit:Keys','Missing grouping identifier.');
    end
end
% Main-cohort case numbers are integers; convert representation only.
c = str2double(T.CaseNo);
if any(~isfinite(c) | c < 1 | c ~= fix(c))
    error('CCEpochAudit:CaseKey','CaseNo must contain positive integer case numbers.');
end
T.CaseNo = string(c);
if any(~ismember(T.State,["Pre","Anterior","Posterior","Post"])) || ...
        any(~ismember(T.Region,["FT","T","TO","CP","PO"]))
    error('CCEpochAudit:Keys','Unexpected state or region label.');
end
end

function k = epochKey(T)
k = groupKey(T) + "|" + compose('%.17g',T.StartSec);
end

function k = groupKey(T)
k = T.CaseNo + "|" + T.State + "|" + T.Region;
end

function P = selectPrimary(E,rules)
requireColumns(E,{'RegionBad','MeanWTC_4_13'});
valid = ~logical(E.RegionBad) & ~isnan(E.MeanWTC_4_13);
if any(isinf(E.MeanWTC_4_13))
    error('CCEpochAudit:WTC','Infinite WTC encountered; selection needs review.');
end
keep = false(height(E),1);
g = findgroups(E.CaseNo,E.State,E.Region);
for j = 1:max(g)
    idx = find(g == j & valid);
    if isempty(idx), continue; end
    st = E.State(idx(1));
    if st == "Pre"
        [~,order] = sort(E.StartSec(idx),'descend');
        if numel(idx) >= rules.PreMin
            keep(idx(order(1:rules.PreMin))) = true;
        end
    elseif st == "Post"
        [~,order] = sort(E.StartSec(idx),'ascend');
        if numel(idx) >= rules.PostMin
            keep(idx(order(1:min(numel(idx),rules.PostMax)))) = true;
        end
    else
        keep(idx) = true;
    end
end
P = E(keep,:);
end

function V = groupedValues(T,col)
requireNumeric(T,col);
if isempty(T)
    V = table(strings(0,1),strings(0,1),strings(0,1),zeros(0,1),zeros(0,1), ...
        'VariableNames',{'CaseNo','State','Region','Value','Count'});
    return
end
[g,c,s,r] = findgroups(T.CaseNo,T.State,T.Region);
x = T.(col);
if any(isinf(x))
    error('CCEpochAudit:InfiniteMetric','Infinite metric value; do not silently omit it.');
end
v = splitapply(@(a) mean(a,'omitnan'),x,g);
n = splitapply(@numel,x,g); % matches groupsummary GroupCount, includes NaNs
V = table(c,s,r,v,n,'VariableNames',{'CaseNo','State','Region','Value','Count'});
end

function T = appendTable(T,U)
if isempty(T), T = U; else, T = [T;U]; end
end

function requireColumns(T,names)
if ~istable(T), error('CCEpochAudit:Table','Expected a saved MATLAB table.'); end
missing = setdiff(names,T.Properties.VariableNames);
if ~isempty(missing)
    error('CCEpochAudit:Columns','Required columns missing: %s',strjoin(missing,', '));
end
end

function requireNumeric(T,name)
requireColumns(T,{name});
if ~isnumeric(T.(name)) || ~iscolumn(T.(name)) || ~isreal(T.(name))
    error('CCEpochAudit:NumericColumn','Expected real numeric vector: %s',name);
end
end

