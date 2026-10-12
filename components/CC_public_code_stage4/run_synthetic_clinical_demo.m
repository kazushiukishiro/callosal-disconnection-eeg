function outDir = run_synthetic_clinical_demo()
%RUN_SYNTHETIC_CLINICAL_DEMO Test additional clinical wrappers on fiction only.
% No patient files, saved cohort models, EDFs, Excel, or base workspace input.
root=fileparts(mfilename('fullpath'));
oldDir=pwd;oldPath=path;oldRng=rng;
restore=onCleanup(@() restoreEnvironment(oldDir,oldPath,oldRng)); %#ok<NASGU>
cd(root);addpath(fullfile(root,'dependencies'),'-begin');
addpath(fullfile(root,'reference'),'-begin');addpath(fullfile(root,'src'),'-begin');
parent=fullfile(root,'clinical_demo_output');
if ~isfolder(parent),[ok,msg]=mkdir(parent);assert(ok,'%s',msg);end
outDir=tempname(parent);[ok,msg]=mkdir(outDir);assert(ok,'%s',msg);
report=fullfile(outDir,'SHARE_STAGE4_REPORT.txt');
local=fullfile(outDir,'LOCAL_DIAGNOSTICS.txt');
reportLines={'CC PUBLIC CODE - STAGE 4 SYNTHETIC CLINICAL TEST'; ...
    'STATUS: RUNNING';['MATLAB: ' version];'PACKAGE: stage4-clinical-v1'; ...
    'New in-memory clinical wrappers plus extracted historical numerical blocks.'; ...
    'Only artificial summary tables and covariates are used.'; ...
    'No clinical findings, thresholds of significance or direction are test targets.'};
writeLines(report,reportLines);localLines={};review=false;stage='package checks';
try
    verifyManifest(root);
    expected={ ...
        'cc_clinical_rank_tests','src';'cc_join_clinical_inputs','src'; ...
        'cc_clinical_test_plan','src';'cc_clinical_modifier_models','src'; ...
        'cc_synthetic_clinical_fixture','src'; ...
        'cc_modifier_reference_blocks','reference'; ...
        'cc_public_group_ops','dependencies';'cc_synthetic_group_fixture','dependencies'; ...
        'cc_connectivity_change_sources','dependencies'};
    for k=1:size(expected,1)
        f=fullfile(root,expected{k,2},[expected{k,1} '.m']);
        assert(samePath(which(expected{k,1}),f),'CCClinicalDemo:Shadowing', ...
            'Unexpected function resolution.');
    end
    assert(exist('fitlme','file')==2 && exist('ranksum','file')==2, ...
        'CCClinicalDemo:Toolbox','Statistics and Machine Learning Toolbox required.');
    reportLines{end+1,1}='PASS: package integrity and explicit function resolution';
    writeLines(report,reportLines);

    fprintf('[1/4] Creating artificial clinical inputs and checking source-specific joins...\n');
    stage='artificial input and source checks';
    rb=rng;F=cc_synthetic_clinical_fixture();
    assert(isequal(rng,rb),'CCClinicalDemo:RNG','Fixture changed caller RNG.');
    inputCopy=F;
    [J,W,C]=cc_join_clinical_inputs(F.Primary,F.Exact,F.Clinical);
    checkSourceJoin(F,J);
    checkBadInputs(F);
    checkTinyRankCases();
    reportLines{end+1,1}=sprintf('FIXTURE: %d fictional covariate rows; %d joined subjects; %d primary regional rows', ...
        height(F.Clinical),height(J),height(W));
    reportLines{end+1,1}='PASS: independent reconstruction of all five primary/exact-time change measures';
    reportLines{end+1,1}='PASS: duplicate keys, invalid coding, Inf and inconsistent MRI codes rejected';
    reportLines{end+1,1}='PASS: small exact-rank example, constant/missing inputs and unavailable groups';
    writeLines(report,reportLines);

    fprintf('[2/4] Checking Spearman, rank-sum and Kruskal-Wallis outputs...\n');
    stage='rank tests';
    plan=cc_clinical_test_plan();
    lastwarn('','');R=cc_clinical_rank_tests(J,plan);[wm,wi]=lastwarn;
    if ~isempty(wm)
        review=true;localLines{end+1,1}=wm;
        reportLines{end+1,1}=['REVIEW: rank-test warning: ' wi];
    end
    checkRankOutputs(J,plan,R);
    writetable(plan,fullfile(outDir,'SYNTHETIC_ONLY_test_plan.csv'));
    writetable(R,fullfile(outDir,'SYNTHETIC_ONLY_rank_results.csv'));
    reportLines{end+1,1}=sprintf('PASS: %d explicitly routed tests; N, medians, statistics and native MATLAB P values',height(R));
    reportLines{end+1,1}='PASS: independent tied-rank Spearman rho, group-0 rank sums and tie-corrected KW statistics';
    reportLines{end+1,1}='Laterality outputs retain both explicitly labelled primary/exact-time routes; no clinical route inferred.';
    writeLines(report,reportLines);

    fprintf('[3/4] Fitting five artificial clinical-modifier models...\n');
    stage='modifier wrapper fits';
    M=cc_clinical_modifier_models(W);
    modelWarnings=M.Warnings.WarningOccurred;
    for k=find(modelWarnings(:))'
        review=true;localLines{end+1,1}=char(M.Warnings.WarningMessage(k)); %#ok<AGROW>
        reportLines{end+1,1}=char("REVIEW: modifier "+M.Warnings.Model(k)+" warning: "+M.Warnings.WarningIdentifier(k)); %#ok<AGROW>
    end
    writetable(M.ANOVA,fullfile(outDir,'SYNTHETIC_ONLY_modifier_anova.csv'));
    writetable(M.Coefficients,fullfile(outDir,'SYNTHETIC_ONLY_modifier_coefficients.csv'));
    reportLines{end+1,1}='PASS: five ML modifier fits (onset, surgery age, duration, joint, standardized joint)';
    writeLines(report,reportLines);

    fprintf('[4/4] Comparing wrappers with extracted source blocks on the same artificial inputs...\n');
    stage='source-block synthetic comparison';
    Ref=cc_modifier_reference_blocks(W);
    checkModifierOutputs(W,M,Ref);
    if any(Ref.Warnings.WarningOccurred)
        review=true;
        for k=find(Ref.Warnings.WarningOccurred(:))'
            localLines{end+1,1}=char(Ref.Warnings.WarningMessage(k)); %#ok<AGROW>
            reportLines{end+1,1}=char("REVIEW: reference "+Ref.Warnings.Model(k)+" warning: "+Ref.Warnings.WarningIdentifier(k)); %#ok<AGROW>
        end
    end
    assert(isequaln(F,inputCopy),'CCClinicalDemo:Mutation','Input data changed.');
    assert(isequaln(C.CaseNo,strip(string(F.Clinical.CaseNo))), ...
        'CCClinicalDemo:ClinicalOrder','Clinical IDs changed unexpectedly.');
    reportLines{end+1,1}='PASS: source-block agreement on synthetic centering, five models, coefficients, CIs, F/P and observation counts';
    reportLines{end+1,1}='PASS: joined-regional-row centering and unique-patient covariate correlations preserved';
    reportLines{end+1,1}='PASS: Satterthwaite omnibus F-tests distinguished from Residual coefficient tests/CIs';
    reportLines{end+1,1}=sprintf('WARNINGS: wrapper fits=%d; reference fits=%d', ...
        sum(M.Warnings.WarningOccurred),sum(Ref.Warnings.WarningOccurred));
    reportLines{end+1,1}='Warning monitoring records only the last warning per test/fit; warnings are not suppressed.';
    reportLines{end+1,1}='NOT TESTED: real clinical outputs, real exclusions, follow-up eligibility, native-rate EDFs or figure export.';
    reportLines{end+1,1}='The test consumes summaries, not the stage-1 EDF output. It is not end-to-end clinical reproduction.';
    reportLines{end+1,1}='All outcome inputs are already masked for eligibility by the caller; no dates are read or eligibility inferred.';
    reportLines{end+1,1}='No study data, clinical expected numbers or previously reported P values were used.';
    reportLines{end+1,1}='A PASS is bounded software-test evidence, not complete manuscript reproducibility.';
    if review,reportLines{2}='STATUS: REVIEW_REQUIRED';else,reportLines{2}='STATUS: PASS';end
catch ME
    reportLines{2}='STATUS: FAIL';
    reportLines{end+1,1}=['FAILED_STAGE: ' stage];
    reportLines{end+1,1}=['ERROR_IDENTIFIER: ' ME.identifier];
    for k=1:min(6,numel(ME.stack))
        reportLines{end+1,1}=sprintf('STACK: %s | line %d',ME.stack(k).name,ME.stack(k).line); %#ok<AGROW>
    end
    localLines{end+1,1}=getReport(ME,'extended','hyperlinks','off');
    fprintf(2,'Stage-4 test stopped: %s\n',ME.message);
end
writeLines(report,reportLines);writeLines(local,localLines);
fprintf('\n%s\nReport: %s\n',reportLines{2},report);
fprintf('Only generated synthetic inputs were used. No clinical sources were read.\n');
end

function checkSourceJoin(F,J)
ids=string(J.CaseNo);expected=nan(numel(ids),5);
states=["Pre","Anterior","Posterior","Post"];
for k=1:numel(ids)
    p=nan(1,4);it=p;in=p;
    for s=1:4
        ix=string(F.Primary.CaseNo)==ids(k)&string(F.Primary.State)==states(s);
        a=F.Primary.Value(ix);a=a(isfinite(a));
        if ~isempty(a),p(s)=sum(a)/numel(a);end
        ix=string(F.Exact.CaseNo)==ids(k)&string(F.Exact.State)==states(s);
        a=F.Exact.MeanWTC(ix&string(F.Exact.ConnectionType)=="Inter");
        if ~isempty(a),it(s)=a;end
        a=F.Exact.MeanWTC(ix&string(F.Exact.ConnectionType)=="Intra");
        if ~isempty(a),in(s)=a;end
    end
    expected(k,:)=[p(1)-p(4),p(2)-p(3),it(1)-it(4),it(2)-it(3), ...
        (it(1)-it(4))-(in(1)-in(4))];
    c=find(string(F.Clinical.CaseNo)==ids(k));
    assert(numel(c)==1,'CCClinicalDemo:Join','Clinical key not unique.');
    names={'AgeOnset','AgeSurgery','Duration','Sex','MRIAbnormality', ...
        'MRILaterality','OverallOutcome','DropOutcome'};
    for j=1:numel(names)
        mustClose(J.(names{j})(k),F.Clinical.(names{j})(c),1e-12,'Keyed covariate');
    end
end
actual=[J.Primary_PrePost,J.Primary_AnteriorPosterior,J.Exact_PrePost, ...
    J.Exact_AnteriorPosterior,J.Exact_Selective];
mustClose(actual,expected,1e-12,'Source-specific metrics');
assert(~any(isfinite(J.Exact_Selective)&~isfinite(J.Exact_PrePost)), ...
    'CCClinicalDemo:Subset','Within-source selective subset is invalid.');
end

function checkBadInputs(F)
C=[F.Clinical;F.Clinical(1,:)];
mustThrow(@() cc_join_clinical_inputs(F.Primary,F.Exact,C),'CCClinical:Duplicate');
C=F.Clinical;C.Sex(1)=3;
mustThrow(@() cc_join_clinical_inputs(F.Primary,F.Exact,C),'CCClinical:BinaryCode');
C=F.Clinical;C.Duration(1)=Inf;
mustThrow(@() cc_join_clinical_inputs(F.Primary,F.Exact,C),'CCClinical:Numeric');
C=F.Clinical;q=find(isfinite(C.MRIAbnormality)&isfinite(C.MRILaterality),1);
C.MRIAbnormality(q)=1-C.MRIAbnormality(q);
mustThrow(@() cc_join_clinical_inputs(F.Primary,F.Exact,C),'CCClinical:MRICoding');
W=[F.Primary;F.Primary(1,:)];
mustThrow(@() cc_join_clinical_inputs(W,F.Exact,F.Clinical),'CCPublic:SourceDuplicate');
E=[F.Exact;F.Exact(1,:)];
mustThrow(@() cc_join_clinical_inputs(F.Primary,E,F.Clinical),'CCPublic:SourceDuplicate');
end

function checkTinyRankCases()
T=table(string((1:6)'),[0;0;0;1;1;1],(1:6)', ...
    'VariableNames',{'CaseNo','Group','Value'});
P=table("toy","RankSum","Group","Value","Toy", ...
    'VariableNames',{'RowID','Test','Variable','Metric','Source'});
R=cc_clinical_rank_tests(T,P);
% All 20 allocations of 3 out of 6 ranks: two extreme allocations -> 0.1.
mustClose(R.P_Unadjusted,0.1,1e-12,'Toy exact P');
mustClose(R.RankSum_Group0,6,1e-12,'Toy rank sum');
T.Value(:)=1;R=cc_clinical_rank_tests(T,P);
assert(R.Status=="CONSTANT_INPUT"&&isnan(R.P_Unadjusted), ...
    'CCClinicalDemo:Constant','Constant input must not be reported as a valid test.');
T.Value=(1:6)';T.Group(:)=0;R=cc_clinical_rank_tests(T,P);
assert(R.Status=="EMPTY_GROUP",'CCClinicalDemo:EmptyGroup','Missing group not flagged.');
P.Test="KW";R=cc_clinical_rank_tests(T,P);
assert(R.Status=="TOO_FEW_GROUPS",'CCClinicalDemo:KWGroups','Single KW group accepted.');
P.Test="Spearman";T.Value(:)=NaN;R=cc_clinical_rank_tests(T,P);
assert(R.N==0&&R.Status=="INSUFFICIENT_N"&&isnan(R.P_Unadjusted), ...
    'CCClinicalDemo:Empty','No complete data incorrectly accepted.');
end

function checkRankOutputs(T,P,R)
assert(height(R)==height(P)&&all(R.Status=="OK"), ...
    'CCClinicalDemo:RankStatus','Unexpected rank result status.');
for k=1:height(P)
    x=T.(char(P.Variable(k)));y=T.(char(P.Metric(k)));
    q=isfinite(x)&isfinite(y);x=x(q);y=y(q);n=numel(x);
    mustClose(R.N(k),n,0,'Complete-case N');
    switch P.Test(k)
        case "Spearman"
            [r,p]=corr(x,y,'Type','Spearman');
            rr=corr(tiedrank(x),tiedrank(y),'Type','Pearson');
            mustClose(R.Rho(k),r,1e-12,'Native Spearman');
            mustClose(R.Rho(k),rr,1e-12,'Independent rank correlation');
        case "RankSum"
            a=y(x==0);b=y(x==1);[p,~,st]=ranksum(a,b);
            ranks=tiedrank([a;b]);
            mustClose(R.RankSum_Group0(k),sum(ranks(1:numel(a))),1e-12,'Pooled group-0 ranks');
            mustClose(R.RankSum_Group0(k),st.ranksum,1e-12,'Native rank sum');
            mustClose([R.N_Group0(k),R.N_Group1(k)],[numel(a),numel(b)],0,'Binary N');
            mustClose([R.Median_Group0(k),R.Median_Group1(k)],[median(a),median(b)],1e-12,'Binary medians');
        case "KW"
            [p,~]=kruskalwallis(y,x,'off');
            rr=tiedrank(y);groups=unique(x);acc=0;
            for g=groups(:)'
                qq=x==g;acc=acc+sum(rr(qq))^2/sum(qq);
            end
            [~,~,gi]=unique(y);ties=accumarray(gi,1);
            correction=1-sum(ties.^3-ties)/(n^3-n);
            H=(12*acc/(n*(n+1))-3*(n+1))/correction;
            mustClose(R.ChiSquare(k),H,1e-9,'Independent KW H');
            mustClose(R.DF(k),numel(groups)-1,0,'KW df');
            mustClose([R.N_Group0(k),R.N_Group1(k),R.N_Group2(k)], ...
                [sum(x==0),sum(x==1),sum(x==2)],0,'KW N');
            mustClose([R.Median_Group0(k),R.Median_Group1(k),R.Median_Group2(k)], ...
                [median(y(x==0)),median(y(x==1)),median(y(x==2))],1e-12,'KW medians');
    end
    mustClose(R.P_Unadjusted(k),p,1e-12,'Native two-sided/default P');
end
assert(~any(R.MultiplicityAdjusted),'CCClinicalDemo:Multiplicity','Unexpected adjustment label.');
end

function checkModifierOutputs(W,M,Ref)
for name={'AgeOnset_c','AgeSurgery_c','Duration_c','AgeOnset_z','Duration_z'}
    mustClose(M.ModelData.(name{1}),Ref.ModelData.(name{1}),1e-12,'Source centering');
end
% Counts must reflect model-specific complete covariates, not whole-cohort N.
needed={{'AgeOnset'},{'AgeSurgery'},{'Duration'}, ...
    {'AgeOnset','Duration'},{'AgeOnset','Duration'}};
for k=1:5
    a=M.ANOVA(M.ANOVA.Model==M.Labels(k),:);b=Ref.ANOVAs{k};
    assert(isequal(a.Term,string(b.Term)),'CCClinicalDemo:Terms','ANOVA terms differ.');
    mustClose([a.FStat,a.DF1,a.DF2,a.P_Unadjusted], ...
        [b.FStat,b.DF1,b.DF2,b.pValue],1e-6,'Source omnibus');
    c=M.Coefficients(M.Coefficients.Model==M.Labels(k),:);d=Ref.Models{k}.Coefficients;
    assert(isequal(c.Term,string(d.Name)),'CCClinicalDemo:Terms','Coefficient terms differ.');
    mustClose([c.Estimate,c.SE,c.tStat,c.DF,c.P_Unadjusted,c.CI_Lower,c.CI_Upper], ...
        [d.Estimate,d.SE,d.tStat,d.DF,d.pValue,d.Lower,d.Upper],1e-7,'Source coefficients');
    good=isfinite(W.mean_MeanWTC_4_13);
    for j=1:numel(needed{k}),good=good&isfinite(W.(needed{k}{j}));end
    mustClose(M.Models{k}.NumObservations,sum(good),0,'Model complete-row count');
    assert(all(a.DFMethod=="Satterthwaite")&&all(c.DFMethod=="Residual"), ...
        'CCClinicalDemo:DFLabels','DF method labels differ.');
    mustClose(c.P_Unadjusted,2*tcdf(-abs(c.tStat),c.DF),1e-12,'Residual t P');
    mustClose(c.CI_Lower,c.Estimate-tinv(0.975,c.DF).*c.SE,1e-12,'Residual lower CI');
    mustClose(c.CI_Upper,c.Estimate+tinv(0.975,c.DF).*c.SE,1e-12,'Residual upper CI');
end
mustClose(M.CovariateRho,Ref.CovariateRho,1e-12,'Covariate Spearman');
mustClose(M.CovariateP,Ref.CovariateP,1e-12,'Covariate P');
end

function mustClose(a,b,tol,label)
assert(isequal(size(a),size(b))&&isequal(isnan(a),isnan(b)), ...
    'CCClinicalDemo:CompareShape','%s: sizes/missingness differ.',label);
q=~isnan(a);
assert(all(isfinite(a(q)))&&all(isfinite(b(q))), ...
    'CCClinicalDemo:CompareFinite','%s: nonfinite output.',label);
d=abs(a(q)-b(q));lim=tol.*max(1,abs(b(q)));
assert(all(d<=lim),'CCClinicalDemo:CompareValue','%s: values differ.',label);
end

function mustThrow(fun,id)
try
    fun();
catch ME
    assert(strcmp(ME.identifier,id),'CCClinicalDemo:UnexpectedError', ...
        'Expected %s; received %s.',id,ME.identifier);
    return
end
error('CCClinicalDemo:NoError','Expected rejection: %s.',id);
end

function verifyManifest(root)
fid=fopen(fullfile(root,'SHA256SUMS.txt'),'r');
assert(fid>=0,'CCSensDemo:Manifest','Manifest missing.');
g=onCleanup(@() fclose(fid)); %#ok<NASGU>
n=0;
while true
    line=fgetl(fid);
    if ~ischar(line), break; end
    if isempty(strtrim(line)), continue; end
    t=regexp(line,'^([0-9a-f]{64})  ([A-Za-z0-9_./-]+)$','tokens','once');
    assert(~isempty(t) && ~startsWith(t{2},'/') && ~contains(t{2},'..'), ...
        'CCSensDemo:Manifest','Invalid manifest entry.');
    f=fullfile(root,strrep(t{2},'/',filesep));
    assert(isfile(f) && strcmp(fileSHA256(f),t{1}), ...
        'CCSensDemo:Checksum','Package file differs: %s',t{2});
    n=n+1;
end
assert(n>=8,'CCSensDemo:Manifest','Package manifest is incomplete.');
end


function tf=samePath(a,b)
a=strrep(char(a),'\','/'); b=strrep(char(b),'\','/');
if ispc, tf=strcmpi(a,b); else, tf=strcmp(a,b); end
end


function writeLines(f,lines)
fid=fopen(f,'w','n','UTF-8');
assert(fid>=0,'CCSensDemo:Report','Cannot write report.');
g=onCleanup(@() fclose(fid)); %#ok<NASGU>
for k=1:numel(lines), fprintf(fid,'%s\n',lines{k}); end
end


function restoreEnvironment(d,p,r)
if isfolder(d), cd(d); end
path(p); rng(r);
end

function h=fileSHA256(f)
fid=fopen(f,'rb');
assert(fid>=0,'CCSensDemo:Hash','Cannot read package file.');
g=onCleanup(@() fclose(fid)); %#ok<NASGU>
b=fread(fid,Inf,'*uint8');
d=java.security.MessageDigest.getInstance('SHA-256');
d.update(typecast(b(:),'int8'));
h=lower(reshape(dec2hex(typecast(d.digest(),'uint8'),2).',1,[]));
end

