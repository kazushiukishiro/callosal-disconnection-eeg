function outDir=run_synthetic_sensitivity_demo()
%RUN_SYNTHETIC_SENSITIVITY_DEMO Synthetic tests for newly packaged sensitivities.
% Reads this package's source/manifest only. No EDF/MAT/Excel input, no base
% workspace access, no clinical exclusions or expected clinical values.
% The 50-resample bootstrap is an integration test, not a precision/CI study.
% Source algorithm's default of 2000 remains in cc_wtc_sensitivity.
root=fileparts(mfilename('fullpath'));
oldDir=pwd; oldPath=path; oldRng=rng;
restore=onCleanup(@() restoreEnvironment(oldDir,oldPath,oldRng)); %#ok<NASGU>
cd(root);
addpath(fullfile(root,'dependencies'),'-begin');
addpath(fullfile(root,'src'),'-begin');
parent=fullfile(root,'sensitivity_demo_output');
if ~isfolder(parent)
    [ok,msg]=mkdir(parent); assert(ok,'CCSensDemo:Output','%s',msg);
end
outDir=tempname(parent);
[ok,msg]=mkdir(outDir); assert(ok,'CCSensDemo:Output','%s',msg);
report=fullfile(outDir,'SHARE_STAGE3_REPORT.txt');
local=fullfile(outDir,'LOCAL_DIAGNOSTICS.txt');
reportLines={'CC PUBLIC CODE - STAGE 3 SYNTHETIC SENSITIVITY TEST'; ...
    'STATUS: RUNNING';['MATLAB: ' version];'PACKAGE: stage3-sensitivity-v2'; ...
    'New callable wrappers, not byte-identical historical analysis scripts.'; ...
    'Only freshly generated artificial summary tables are analysed.'; ...
    'Not an EDF-to-cohort or real-cohort numerical reproduction.'; ...
    'BOOTSTRAP TEST: 50 resamples; not the 2000-resample default study-code run.'};
writeLines(report,reportLines);
localLog={}; review=false; stage='package checks';
try
    verifyManifest(root);
    files={ ...
        'cc_wtc_sensitivity',fullfile(root,'src','cc_wtc_sensitivity.m'); ...
        'cc_synthetic_group_fixture',fullfile(root,'dependencies','cc_synthetic_group_fixture.m'); ...
        'cc_public_group_ops',fullfile(root,'dependencies','cc_public_group_ops.m')};
    for k=1:size(files,1)
        assert(samePath(which(files{k,1}),files{k,2}), ...
            'CCSensDemo:Shadowing','Unexpected function resolution.');
    end
    assert(exist('fitlme','file')==2,'CCSensDemo:Toolbox', ...
        'Statistics and Machine Learning Toolbox is required.');
    reportLines{end+1,1}='PASS: package integrity and explicit function resolution';
    % Check the mathematical log call in the SAME workspace as report storage.
    % A report variable called log shadowed this function in version 1.
    stage='natural-log namespace check';
    assert(exist('log','var')==0,'CCSensDemo:LogShadowing', ...
        'The demo workspace must not define a variable named log.');
    assert(max(abs(log([exp(-1);1;exp(1)])-[-1;0;1]))<1e-12, ...
        'CCSensDemo:LogFunction','Unexpected natural-log probe result.');
    reportLines{end+1,1}='PASS: natural-log call in the report-writing workspace';
    writeLines(report,reportLines);

    fprintf('[1/4] Creating artificial tables and checking boundary/resampling rules...\n');
    stage='synthetic fixture and input tests';
    F=cc_synthetic_group_fixture();
    E=F.Epochs;
    P=cc_public_group_ops('select_primary',E,F.Rules);
    bad=P.CaseNo==F.ExcludedGroup.CaseNo & ...
        P.State==F.ExcludedGroup.State & P.Region==F.ExcludedGroup.Region;
    P=P(~bad,:);
    V=cc_public_group_ops('value_epochs',P,'MeanWTC_4_13');
    [W,~,~]=cc_public_group_ops('summarize',V,'WTC','Matched');
    W=W(:,{'CaseNo','State','Region','Value'});
    W.Properties.VariableNames{4}='mean_MeanWTC_4_13';
    X=F.Exact;
    originalW=W; originalX=X;
    checkUnitInputs(W,X);
    reportLines{end+1,1}=sprintf('FIXTURE: %d fictional subjects; %d regional and %d exact-time summaries', ...
        F.NumberOfArtificialSubjects,height(W),height(X));
    reportLines{end+1,1}='PASS: boundary transform, duplicate rejection, missing-pair rejection';
    reportLines{end+1,1}='PASS: repeated patients preserve all rows but receive distinct bootstrap cluster IDs';
    writeLines(report,reportLines);

    fprintf('[2/4] Testing the documented logit-WTC sensitivity...\n');
    stage='logit synthetic fit';
    G=cc_wtc_sensitivity('logit',W);
    stage='logit output verification';
    expectedY=min(max(W.mean_MeanWTC_4_13,1e-6),1-1e-6);
    assert(max(abs(G.TransformedValues-log(expectedY./(1-expectedY))))<1e-12, ...
        'CCSensDemo:Transform','Logit transform does not match the documented bound.');
    assert(height(G.Summary)==1 && G.Summary.N_Observations==height(W), ...
        'CCSensDemo:LogitRows','Logit fit observation count differs.');
    writetable(G.Summary,fullfile(outDir,'SYNTHETIC_ONLY_logit_summary.csv'));
    writetable(G.Coefficients,fullfile(outDir,'SYNTHETIC_ONLY_logit_coefficients.csv'));
    review=review || any(G.Summary.WarningOccurred);
    if any(G.Summary.WarningOccurred)
        localLog{end+1,1}=char(G.Summary.WarningMessage(1));
        reportLines{end+1,1}=['REVIEW: logit warning: ' char(G.Summary.WarningIdentifier(1))];
    end
    reportLines{end+1,1}='PASS: logit transform/model interface; explicit Satterthwaite F and Residual coefficients';
    writeLines(report,reportLines);

    fprintf('[3/4] Leaving out each artificial subject for three model families...\n');
    stage='leave-one-out fits';
    [L,C]=cc_wtc_sensitivity('loo',W,X);
    checkLOO(L,W,X);
    assert(all(C.DFMethod=="Residual"),'CCSensDemo:DF','Coefficient DF label differs.');
    writetable(L,fullfile(outDir,'SYNTHETIC_ONLY_loo_omnibus.csv'));
    writetable(C,fullfile(outDir,'SYNTHETIC_ONLY_loo_coefficients.csv'));
    reportLines{end+1,1}=sprintf('PASS: %d leave-one-out fits; case/observation deletion checked independently',height(L));
    reportLines{end+1,1}='No direction or significance threshold was used as a pass criterion.';
    if any(L.WarningOccurred)
        review=true;
        rows=find(L.WarningOccurred);
        reportLines{end+1,1}=sprintf('REVIEW: %d LOO fits recorded warnings',numel(rows));
        for k=rows(:)'
            localLog{end+1,1}=char(L.Model(k)+": "+L.WarningMessage(k)); %#ok<AGROW>
        end
    end
    writeLines(report,reportLines);
    writeLines(local,localLog);

    fprintf('[4/4] Testing patient-cluster refits with 50 artificial bootstrap draws...\n');
    stage='patient-cluster bootstrap';
    rngBefore=rng;
    B=cc_wtc_sensitivity('bootstrap',W,X,50,20260820);
    assert(isequal(rng,rngBefore),'CCSensDemo:RNG','Bootstrap changed the caller RNG state.');
    checkBootstrap(B,W);
    assert(isequaln(W,originalW) && isequaln(X,originalX), ...
        'CCSensDemo:Mutation','Caller input tables changed.');
    % Every result filename records the short, synthetic-only test scope.
    writetable(B.Summary,fullfile(outDir,'SYNTHETIC_ONLY_bootstrap50_summary.csv'));
    writetable(B.FitStatus,fullfile(outDir,'SYNTHETIC_ONLY_bootstrap50_fit_status.csv'));
    writematrix(B.PrimaryDraws,fullfile(outDir,'SYNTHETIC_ONLY_bootstrap50_primary_draws.csv'));
    writematrix(B.ExactDraws,fullfile(outDir,'SYNTHETIC_ONLY_bootstrap50_exact_draws.csv'));
    warnFits=strlength(string(B.FitStatus.WarningMessage))>0;
    failed=~B.FitStatus.Succeeded;
    review=review || any(warnFits) || any(failed) || any(B.BaselineWarnings.WarningOccurred);
    reportLines{end+1,1}=sprintf('BOOTSTRAP: requested=%d; primary successful=%d; exact successful=%d', ...
        B.Replicates,B.Summary.SuccessfulReplicates(1),B.Summary.SuccessfulReplicates(4));
    reportLines{end+1,1}=sprintf('BOOTSTRAP REVIEW COUNTS: failed fits=%d; fits with recorded warnings=%d; baseline warnings=%d', ...
        nnz(failed),nnz(warnFits),nnz(B.BaselineWarnings.WarningOccurred));
    reportLines{end+1,1}='PASS: bootstrap draws, paired model sampling, percentile construction, failure accounting and RNG restoration';
    reportLines{end+1,1}='The short-test percentile intervals are not reported manuscript confidence intervals.';
    for k=find(warnFits | failed)'
        localLog{end+1,1}=char(string(B.FitStatus.Model(k))+": "+ ...
            string(B.FitStatus.ErrorMessage(k))+" "+string(B.FitStatus.WarningMessage(k))); %#ok<AGROW>
    end
    for k=find(B.BaselineWarnings.WarningOccurred)'
        localLog{end+1,1}=char(string(B.BaselineWarnings.WarningMessage(k))); %#ok<AGROW>
    end
    if review, reportLines{2}='STATUS: REVIEW_REQUIRED'; else, reportLines{2}='STATUS: PASS'; end
    reportLines{end+1,1}='Warning monitoring records the last warning per fit/test; warnings are not suppressed.';
    reportLines{end+1,1}='NOT TESTED: full 2000-resample run, native-rate EDFs, clinical modifiers/rank tests, figure export.';
    reportLines{end+1,1}='NOT TESTED: real-cohort exclusions, original-versus-wrapper clinical numerical equivalence.';
    reportLines{end+1,1}='No patient files or expected clinical effect sizes, P values or sample counts were used.';
    reportLines{end+1,1}='A PASS is bounded software-test evidence, not complete manuscript reproducibility.';
catch ME
    reportLines{2}='STATUS: FAIL';
    reportLines{end+1,1}=['FAILED_STAGE: ' stage];
    reportLines{end+1,1}=['ERROR_IDENTIFIER: ' ME.identifier];
    for k=1:numel(ME.stack)
        reportLines{end+1,1}=sprintf('STACK: %s | line %d',ME.stack(k).name,ME.stack(k).line); %#ok<AGROW>
    end
    localLog{end+1,1}=getReport(ME,'extended','hyperlinks','off');
    fprintf(2,'Stage-3 test stopped: %s\n',ME.message);
end
writeLines(report,reportLines);
writeLines(local,localLog);
fprintf('\n%s\nReport: %s\n',reportLines{2},report);
fprintf('Only newly generated artificial tables were used.\n');
end

function checkUnitInputs(W,X)
y=[0;1e-7;1e-6;0.2;0.5;0.8;1-1e-6;1-1e-7;1];
[z,S]=cc_wtc_sensitivity('logit_values',y);
q=min(max(y,1e-6),1-1e-6);
assert(max(abs(z-log(q./(1-q))))<1e-12 && S.NumericallyChanged==4 && ...
    S.AtOrBelowLowerBound==3 && S.AtOrAboveUpperBound==3, ...
    'CCSensDemo:LogitBoundary','Unexpected logit boundary handling.');
expectError(@() cc_wtc_sensitivity('logit_values',[-0.01;0.5]), ...
    'CCWtcSensitivity:LogitInput');
expectError(@() cc_wtc_sensitivity('logit_values',[NaN;0.5]), ...
    'CCWtcSensitivity:LogitInput');
c=unique(string(W.CaseNo));
draw=[c(1);c(1);c(end)];
[Wb,Xb]=cc_wtc_sensitivity('resample',W,X,draw);
assert(numel(unique(string(Wb.BootCase)))==3 && ...
    numel(unique(string(Xb.BootCase)))==3, ...
    'CCSensDemo:Cluster','Repeated draws were merged.');
for j=1:numel(draw)
    a=W(string(W.CaseNo)==draw(j),:);
    b=Wb(string(Wb.BootCase)=="B"+string(j),:);
    assert(height(a)==height(b) && ...
        isequal(a.mean_MeanWTC_4_13,b.mean_MeanWTC_4_13) && ...
        isequal(string(a.State),string(b.State)) && isequal(string(a.Region),string(b.Region)), ...
        'CCSensDemo:ClusterRows','Regional observations were not preserved.');
    a=X(string(X.CaseNo)==draw(j),:);
    b=Xb(string(Xb.BootCase)=="B"+string(j),:);
    assert(height(a)==height(b) && isequal(a.MeanWTC,b.MeanWTC), ...
        'CCSensDemo:ClusterRows','Exact-time observations were not preserved.');
end
r1=unique(string(Wb.BootCaseRegion(string(Wb.BootCase)=="B1")));
r2=unique(string(Wb.BootCaseRegion(string(Wb.BootCase)=="B2")));
assert(isempty(intersect(r1,r2)),'CCSensDemo:NestedCluster','Nested IDs reused.');
expectError(@() cc_wtc_sensitivity('resample',[W;W(1,:)],X,draw), ...
    'CCWtcSensitivity:Duplicate');
expectError(@() cc_wtc_sensitivity('resample',W,X(2:end,:),draw), ...
    'CCWtcSensitivity:Pair');
Q=W; Q.mean_MeanWTC_4_13(1)=Inf;
expectError(@() cc_wtc_sensitivity('resample',Q,X,draw), ...
    'CCWtcSensitivity:WTC');
end

function checkLOO(L,W,X)
sets={W,W,X}; labels={'Primary','Region','Exact'};
expectedRows=0;
for j=1:3
    T=sets{j}; ids=unique(string(T.CaseNo));
    expectedRows=expectedRows+numel(ids);
    for k=1:numel(ids)
        hit=L.Model==string(labels{j}) & L.ExcludedCase==ids(k);
        expectedN=nnz(string(T.CaseNo)~=ids(k));
        assert(nnz(hit)==1 && L.N_Observations(hit)==expectedN && ...
            L.N_Cases(hit)==numel(ids)-1, ...
            'CCSensDemo:LOORows','A LOO omission or count is incorrect.');
    end
end
assert(height(L)==expectedRows && all(L.DFMethod=="Satterthwaite") && ...
    all(isfinite([L.FStat;L.DF1;L.DF2;L.P_Unadjusted])), ...
    'CCSensDemo:LOO','Incomplete or invalid LOO output.');
end

function checkBootstrap(B,W)
assert(B.Replicates==50 && height(B.Summary)==6 && height(B.FitStatus)==100, ...
    'CCSensDemo:BootstrapCount','Short-test replicate count differs.');
n=numel(unique(string(W.CaseNo)));
assert(isequal(size(B.SampleIndices),[n,50]) && ...
    all(B.SampleIndices(:)>=1 & B.SampleIndices(:)<=n), ...
    'CCSensDemo:BootstrapIndices','Invalid cluster draw matrix.');
draws={B.PrimaryDraws,B.ExactDraws}; labels={'Primary','Exact'};
for j=1:2
    D=draws{j}; ok=all(isfinite(D),2);
    F=B.FitStatus(string(B.FitStatus.Model)==string(labels{j}),:);
    assert(isequal(F.Succeeded,ok),'CCSensDemo:FailureAccounting', ...
        'Failure flags and coefficient arrays disagree.');
    for k=1:3
        r=(j-1)*3+k;
        assert(B.Summary.SuccessfulReplicates(r)==nnz(ok) && ...
            B.Summary.FailedReplicates(r)==50-nnz(ok), ...
            'CCSensDemo:FailureAccounting','Failed replicates omitted from summary.');
        if nnz(ok)>=2
            q=prctile(D(ok,k),[2.5 97.5]);
            actual=[B.Summary.CI_Lower(r),B.Summary.CI_Upper(r)];
            assert(max(abs(q-actual))<1e-12 && ...
                abs(B.Summary.ProportionNegative(r)-mean(D(ok,k)<0))<1e-12, ...
                'CCSensDemo:Percentile','Percentile/direction summaries differ.');
        else
            assert(all(isnan([B.Summary.CI_Lower(r),B.Summary.CI_Upper(r)])), ...
                'CCSensDemo:Percentile','A CI was given without enough valid replicates.');
        end
    end
end
end

function expectError(fn,id)
caught=false;
try
    fn();
catch ME
    caught=strcmp(ME.identifier,id);
    if ~caught, rethrow(ME); end
end
assert(caught,'CCSensDemo:ExpectedError','Expected input rejection did not occur.');
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

function h=fileSHA256(f)
fid=fopen(f,'rb');
assert(fid>=0,'CCSensDemo:Hash','Cannot read package file.');
g=onCleanup(@() fclose(fid)); %#ok<NASGU>
b=fread(fid,Inf,'*uint8');
d=java.security.MessageDigest.getInstance('SHA-256');
d.update(typecast(b(:),'int8'));
h=lower(reshape(dec2hex(typecast(d.digest(),'uint8'),2).',1,[]));
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
