function R = cc_clinical_rank_tests(T,plan)
%CC_CLINICAL_RANK_TESTS In-memory, explicitly routed clinical rank tests.
% T: one row per pseudonymous CaseNo. No files or base workspace are read.
% plan: RowID, Test, Variable, Metric, Source. Test is Spearman/RankSum/KW.
% Source labels are metadata; Metric must name the actual source-specific
% column. The calling code must choose it explicitly (never choose by P).
% Complete cases are selected separately for every row. All P values are
% unadjusted. Undefined tests retain a reason and NaN, not a replacement P.
assert(istable(T)&&istable(plan),'CCClinical:Table','Table inputs required.');
need(T,{'CaseNo'});
need(plan,{'RowID','Test','Variable','Metric','Source'});
ids=string(T.CaseNo);
assert(all(~ismissing(ids)&strlength(strtrim(ids))>0) && ...
    numel(unique(ids))==height(T),'CCClinical:Duplicate', ...
    'One nonmissing unique CaseNo is required per clinical row.');
for key={'RowID','Test','Variable','Metric','Source'}
    plan.(key{1})=string(plan.(key{1}));
    assert(all(~ismissing(plan.(key{1})) & strlength(plan.(key{1}))>0), ...
        'CCClinical:Plan','Missing plan field.');
end
assert(numel(unique(plan.RowID))==height(plan),'CCClinical:Plan','Duplicate RowID.');
rows=cell(0,20);
for k=1:height(plan)
    vn=char(plan.Variable(k)); mn=char(plan.Metric(k));
    need(T,{vn,mn});
    x=T.(vn); y=T.(mn);
    assert(isnumeric(x)&&isreal(x)&&iscolumn(x)&& ...
        isnumeric(y)&&isreal(y)&&iscolumn(y),'CCClinical:Numeric', ...
        'Numeric column inputs required.');
    assert(~any(isinf(x))&&~any(isinf(y)),'CCClinical:Infinite', ...
        'Infinity is invalid; it is not silently treated as missing.');
    ok=isfinite(x)&isfinite(y); x=x(ok); y=y(ok); n=numel(x);
    n0=NaN;n1=NaN;n2=NaN;m0=NaN;m1=NaN;m2=NaN;
    rho=NaN;rankSum=NaN;chi2=NaN;df=NaN;p=NaN;
    state="OK";method="";
    switch plan.Test(k)
        case "Spearman"
            method="MATLAB corr Spearman default two-sided";
            if n<3
                state="INSUFFICIENT_N";
            elseif numel(unique(x))<2 || numel(unique(y))<2
                state="CONSTANT_INPUT";
            else
                [rho,p]=corr(x,y,'Type','Spearman');
            end
        case "RankSum"
            assert(all(ismember(x,[0 1])),'CCClinical:BinaryCode', ...
                'RankSum group values must be 0/1 or NaN.');
            a=y(x==0);b=y(x==1);n0=numel(a);n1=numel(b);
            m0=median(a,'omitnan');m1=median(b,'omitnan');
            if isempty(a)||isempty(b)
                state="EMPTY_GROUP";method="Not evaluated";
            elseif numel(unique(y))<2
                state="CONSTANT_INPUT";method="Not evaluated";
            else
                % Do not silently force approximate/exact inference.
                [p,~,st]=ranksum(a,b);
                rankSum=st.ranksum;
                if isfield(st,'zval') && ~isempty(st.zval)
                    method="MATLAB ranksum default approximate";
                else
                    method="MATLAB ranksum default exact";
                end
            end
        case "KW"
            assert(all(ismember(x,[0 1 2])),'CCClinical:LateralityCode', ...
                'KW groups must be 0/1/2 or NaN.');
            n0=sum(x==0);n1=sum(x==1);n2=sum(x==2);
            m0=median(y(x==0),'omitnan');m1=median(y(x==1),'omitnan');
            m2=median(y(x==2),'omitnan');method="MATLAB kruskalwallis";
            if numel(unique(x))<2
                state="TOO_FEW_GROUPS";
            elseif numel(unique(y))<2
                state="CONSTANT_INPUT";
            else
                [p,tbl]=kruskalwallis(y,x,'off');
                % MATLAB's ANOVA-style table: df is column 3; Chi-sq is 5.
                df=tbl{2,3};chi2=tbl{2,5};
                assert(isnumeric(df)&&isscalar(df)&&isnumeric(chi2)&& ...
                    isscalar(chi2),'CCClinical:KWOutput','Unexpected KW output.');
            end
        otherwise
            error('CCClinical:Plan','Unknown test type.');
    end
    if state=="OK"
        assert(isfinite(p)&&p>=0&&p<=1,'CCClinical:InvalidP','Invalid P value.');
    end
    rows(end+1,:)={plan.RowID(k),plan.Test(k),plan.Variable(k), ...
        plan.Metric(k),plan.Source(k),n,n0,n1,n2,m0,m1,m2, ...
        rho,rankSum,chi2,df,p,state,method,false}; %#ok<AGROW>
end
R=cell2table(rows,'VariableNames',{'RowID','Test','Variable','Metric', ...
    'Source','N','N_Group0','N_Group1','N_Group2','Median_Group0', ...
    'Median_Group1','Median_Group2','Rho','RankSum_Group0','ChiSquare', ...
    'DF','P_Unadjusted','Status','Method','MultiplicityAdjusted'});
end

function need(T,names)
assert(all(ismember(names,T.Properties.VariableNames)), ...
    'CCClinical:Columns','Required input columns missing.');
end
