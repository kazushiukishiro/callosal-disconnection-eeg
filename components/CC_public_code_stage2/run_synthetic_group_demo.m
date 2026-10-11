function outDir = run_synthetic_group_demo()
%RUN_SYNTHETIC_GROUP_DEMO Stage-2 public-code integration smoke test.
% NEW TEST HARNESS. Reads package files only and generates artificial tables.
% No EDF, clinical Excel, patient MAT, frozen model, or base-workspace access.
% New fits below use only newly generated synthetic summary observations.
% Does not reproduce, revise or validate the numerical clinical results.
% Requires MATLAB R2026a and Statistics and Machine Learning Toolbox.
% Package authoring environment did not execute this function in MATLAB.
root=fileparts(mfilename('fullpath'));
oldDir=pwd;oldPath=path;oldRng=rng;
restore=onCleanup(@() restoreEnvironment(oldDir,oldPath,oldRng)); %#ok<NASGU>
cd(root);addpath(fullfile(root,'src'),'-begin');
parent=fullfile(root,'group_demo_output');
if ~isfolder(parent),[ok,msg]=mkdir(parent);assert(ok,'CCGroupDemo:Output','%s',msg);end
outDir=tempname(parent);[ok,msg]=mkdir(outDir);assert(ok,'CCGroupDemo:Output','%s',msg);
report=fullfile(outDir,'SHARE_STAGE2_REPORT.txt');
local=fullfile(outDir,'LOCAL_DIAGNOSTICS.txt');
log={'CC PUBLIC CODE - STAGE 2 SYNTHETIC GROUP TEST';'STATUS: RUNNING'; ...
    ['MATLAB: ' version]; 'PACKAGE: stage2-v3'; ...
    'Only newly generated artificial SUMMARY tables are analysed.'; ...
    'These tables are not patient data or outputs of the stage-1 EDF demo.'; ...
    'This is not a reproduction of the 32-patient clinical results.'};
writeLines(report,log);localLog={};review=false;stage='package checks';
try
    verifyManifest(root);
    funcs={'cc_public_group_ops','cc_synthetic_group_fixture', ...
        'cc_connectivity_change_sources','cc_regional_contrasts'};
    for k=1:numel(funcs)
        f=which(funcs{k});expected=fullfile(root,'src',[funcs{k} '.m']);
        assert(samePath(f,expected),'CCGroupDemo:Shadowing','Unexpected function resolution.');
    end
    assert(exist('fitlme','file')==2,'CCGroupDemo:Toolbox', ...
        'Statistics and Machine Learning Toolbox is required.');
    products=ver;
    for k=1:numel(products)
        if ismember(products(k).Name,{'MATLAB','Statistics and Machine Learning Toolbox'})
            log{end+1,1}=sprintf('PRODUCT: %s | %s',products(k).Name,products(k).Version);
        end
    end
    log{end+1,1}='PASS: package checksums and function resolution';writeLines(report,log);

    fprintf('[1/5] Checking selection, matching and normalization interfaces...\n');
    stage='selection and normalization unit tests';
    checkSmallExamples();
    log{end+1,1}='PASS: small-example grouping, patient-first normalization and strict key/value checks';
    % Record the two empty-array shapes instead of inferring them from a FAIL.
    probe=(1:3)';emptyLogical=probe(false(3,1));emptyBracket=probe([]);
    log{end+1,1}=sprintf( ...
        'EMPTY_VECTOR_PROBE: logical=%s; bracket=%s; direct_equal=%d; column_equal=%d', ...
        mat2str(size(emptyLogical)),mat2str(size(emptyBracket)), ...
        isequal(emptyLogical,emptyBracket),sameStartTimes(emptyLogical,emptyBracket));
    stage='selection boundary regression tests';
    checkSelectionEdges();
    log{end+1,1}='PASS: selection boundary tests (10 synthetic groups), empty-vector shape handling and rejection of wrong times/counts';
    writeLines(report,log);
    stage='synthetic fixture creation';
    F=cc_synthetic_group_fixture();E=F.Epochs;
    P0=cc_public_group_ops('select_primary',E,F.Rules);
    % Explicit synthetic regional exclusion AFTER selection. No refill.
    bad=P0.CaseNo==F.ExcludedGroup.CaseNo & P0.State==F.ExcludedGroup.State & ...
        P0.Region==F.ExcludedGroup.Region;
    assert(nnz(bad)==F.Rules.PreMin,'CCGroupDemo:FictionalExclusion', ...
        'Fictional regional exclusion did not cover the selected group.');
    P=P0(~bad,:);
    stage='synthetic fixture selection verification';
    verifySelection(E,P0,F.Rules);
    log{end+1,1}='PASS: key uniqueness, missing/nonfinite rejection, patient-first normalization';
    log{end+1,1}='PASS: Pre/Post selection limits and explicit fictional post-selection exclusion without refill';
    log{end+1,1}=sprintf('FIXTURE: %d fictional subjects; no clinical counts used as targets',F.NumberOfArtificialSubjects);
    writeLines(report,log);

    names={'WTC','dwPLI','Delta','Theta','Alpha','Beta','RMS','Power1_40','RelativePower4_13'};
    cols={'MeanWTC_4_13','MeanDwPLI_4_13','MeanWTC_Delta','MeanWTC_Theta', ...
        'MeanWTC_Alpha','MeanWTC_Beta','MeanRMS','MeanPower1_40','RelativePower4_13'};
    regional=cell(size(names));patient=cell(size(names));originalPatient=cell(size(names));desc=table;
    for k=1:numel(names)
        if k==1
            O=cc_public_group_ops('value_epochs',P,cols{k});
        else
            O=cc_public_group_ops('value_epochs',E(~E.RegionBad,:),cols{k});
            q=O.CaseNo==F.ExcludedGroup.CaseNo & O.State==F.ExcludedGroup.State & ...
                O.Region==F.ExcludedGroup.Region;
            O=O(~q,:);
        end
        M=cc_public_group_ops('match',P,O,names{k});
        [regional{k},patient{k},d1]=cc_public_group_ops('summarize',M,names{k},'Matched');
        [~,originalPatient{k},d0]=cc_public_group_ops('summarize',O,names{k},'Original');
        if isempty(desc),desc=[d0;d1];else,desc=[desc;d0;d1];end %#ok<AGROW>
        assert(isequal(cc_public_group_ops('keys',M),cc_public_group_ops('keys',P)), ...
            'CCGroupDemo:Matching','Different primary keys across metrics.');
    end
    writetable(desc,fullfile(outDir,'SYNTHETIC_ONLY_descriptive.csv'));
    log{end+1,1}='PASS: all eight complementary metrics cover identical primary-selected keys';
    log{end+1,1}=sprintf('SYNTHETIC COUNTS: candidate rows=%d; selected after fictional exclusion=%d; regional rows=%d', ...
        height(E),height(P),height(regional{1}));writeLines(report,log);

    fprintf('[2/5] Fitting artificial primary, regional and exact-time models...\n');
    stage='primary regional and exact-time synthetic models';
    V=cc_public_group_ops('model_table',regional{1});
    X=F.Exact;X.CaseNo=categorical(X.CaseNo);
    X.State=categorical(X.State,{'Pre','Anterior','Posterior','Post'});
    X.ConnectionType=categorical(X.ConnectionType,{'Intra','Inter'});
    models=cell(1,3);
    modelNames={'Primary','Region','Exact'};
    data={V,V,X};
    formulas={'Value ~ State + Region + (1|CaseNo) + (1|CaseNo:Region)', ...
        'Value ~ State*Region + (1|CaseNo) + (1|CaseNo:Region)', ...
        'MeanWTC ~ State*ConnectionType + (1|CaseNo)'};
    coef=table;omnibus=table;
    for k=1:3
        lastwarn('');models{k}=fitlme(data{k},formulas{k},'FitMethod','ML');
        T=cc_public_group_ops('omnibus',models{k},modelNames{k},height(data{k}));
        checkOmnibus(T);omnibus=append(omnibus,T);
        R=checkInference(models{k},modelNames{k},height(data{k}));coef=append(coef,R);
        [msg,id]=lastwarn;
        if ~isempty(msg)
            review=true;localLog{end+1,1}=[modelNames{k} ': ' msg]; %#ok<AGROW>
            log{end+1,1}=sprintf('REVIEW: %s warning identifier=%s',modelNames{k},id);
        else
            log{end+1,1}=['PASS: ' modelNames{k} ' synthetic model and explicit DF checks'];
        end
        writeLines(report,log);
    end
    Qregion=cc_regional_contrasts(models{2});
    assert(height(Qregion)==15 && all(Qregion.P_Holm>=Qregion.P_Unadjusted-1e-14), ...
        'CCGroupDemo:Holm','Regional contrast family is invalid.');
    [~,ix]=sort(Qregion.P_Unadjusted);
    assert(all(diff(Qregion.P_Holm(ix))>=-1e-14),'CCGroupDemo:Holm','Nonmonotone adjusted P values.');
    writetable(Qregion,fullfile(outDir,'SYNTHETIC_ONLY_regional_contrasts.csv'));
    log{end+1,1}='PASS: 15 regional contrast construction and Holm adjustment invariants';

    fprintf('[3/5] Fitting artificial epoch-matched complementary models...\n');
    stage='complementary synthetic models';contrasts=table;
    for k=2:numel(names)
        T=cc_public_group_ops('model_table',regional{k});
        lastwarn('');m=fitlme(T,formulas{1},'FitMethod','ML');
        A=cc_public_group_ops('omnibus',m,names{k},height(T));checkOmnibus(A);
        Q=cc_public_group_ops('contrasts',m,names{k},height(T));checkContrasts(m,Q);
        omnibus=append(omnibus,A);contrasts=append(contrasts,Q);
        [msg,id]=lastwarn;
        if ~isempty(msg)
            review=true;localLog{end+1,1}=[names{k} ': ' msg]; %#ok<AGROW>
            log{end+1,1}=sprintf('REVIEW: %s warning identifier=%s',names{k},id);
        else
            log{end+1,1}=['PASS: ' names{k} ' synthetic ML model and Satterthwaite contrasts'];
        end
        writeLines(report,log);
    end
    L=table;
    for k=3:6
        T=cc_public_group_ops('model_table',regional{k});
        T.FrequencyBand=categorical(repmat(string(names{k}),height(T),1), ...
            {'Delta','Theta','Alpha','Beta'});
        L=append(L,T);
    end
    lastwarn('');mBand=fitlme(L, ...
        'Value ~ State*FrequencyBand + Region + (1|CaseNo) + (1|CaseNo:Region)', ...
        'FitMethod','ML');
    A=cc_public_group_ops('omnibus',mBand,'FrequencyInteraction',height(L));checkOmnibus(A);
    omnibus=append(omnibus,A);
    [msg,id]=lastwarn;
    if ~isempty(msg)
        review=true;localLog{end+1,1}=['FrequencyInteraction: ' msg];
        log{end+1,1}=['REVIEW: FrequencyInteraction warning identifier=' id];
    else
        log{end+1,1}='PASS: artificial State x FrequencyBand model';
    end
    % Generalize the output label: Exact observations do not have regions.
    ix=find(strcmp(omnibus.Properties.VariableNames,'N_RegionalObservations'));
    omnibus.Properties.VariableNames{ix}='N_Observations';
    omnibus.ObservationUnit=repmat("subject-state-region",height(omnibus),1);
    omnibus.ObservationUnit(omnibus.Model=="Exact")="subject-state-connection-type";
    omnibus.ObservationUnit(omnibus.Model=="FrequencyInteraction")="subject-state-region-band";
    writetable(omnibus,fullfile(outDir,'SYNTHETIC_ONLY_omnibus.csv'));
    writetable(coef,fullfile(outDir,'SYNTHETIC_ONLY_coefficients_by_df.csv'));
    writetable(contrasts,fullfile(outDir,'SYNTHETIC_ONLY_lmm_contrasts.csv'));
    writeLines(report,log);

    fprintf('[4/5] Checking paired-patient bootstrap on artificial dwPLI...\n');
    stage='synthetic paired-patient bootstrap';
    before=rng;
    Q1=cc_public_group_ops('bootstrap_dwpli',patient{2},'dwPLI_Matched');
    after=rng;assert(isequal(before,after),'CCGroupDemo:RNG','Bootstrap changed caller RNG.');
    Q0=cc_public_group_ops('bootstrap_dwpli',originalPatient{2},'dwPLI_Original');
    Qrepeat=cc_public_group_ops('bootstrap_dwpli',patient{2},'dwPLI_Matched');
    assert(isequaln(Q1,Qrepeat),'CCGroupDemo:BootstrapRepeat','Fixed-seed bootstrap is not reproducible.');
    checkBootstrapMeans(patient{2},Q1);checkBootstrapMeans(originalPatient{2},Q0);
    writetable([Q0;Q1],fullfile(outDir,'SYNTHETIC_ONLY_dwpli_bootstrap.csv'));
    log{end+1,1}='PASS: 10000 paired-patient bootstrap replicates per contrast; pairing, mean differences, RNG restoration';
    log{end+1,1}='Bootstrap inference is descriptive test output only; no clinical or significance target was imposed.';
    writeLines(report,log);

    fprintf('[5/5] Checking primary/exact-time metric-source separation...\n');
    stage='clinical metric-source interface (no clinical tests)';
    S=cc_connectivity_change_sources(regional{1},F.Exact);
    i=S.CaseNo=="910001";
    assert(nnz(i)==1 && isnan(S.Primary_PrePost(i)) && isfinite(S.Exact_Selective(i)), ...
        'CCGroupDemo:DistinctSources','Separate-source missingness was not preserved.');
    i=S.CaseNo=="910002";
    assert(nnz(i)==1 && isfinite(S.Primary_PrePost(i)) && isnan(S.Exact_Selective(i)), ...
        'CCGroupDemo:DistinctSources','Exact-time missingness was not preserved.');
    T=F.Exact;
    T(T.CaseNo=="910005" & T.State=="Post" & T.ConnectionType=="Intra",:)=[];
    S2=cc_connectivity_change_sources(regional{1},T);i=S2.CaseNo=="910005";
    assert(isfinite(S2.Exact_PrePost(i)) && isnan(S2.Exact_Selective(i)), ...
        'CCGroupDemo:IncompletePair','Missing Intra should invalidate selective but not Inter difference.');
    log{end+1,1}='PASS: primary/exact-time source separation; selective within-source subset and incomplete-pair handling';
    log{end+1,1}='NOT TESTED: 1000/2000-Hz EDFs; this stage has no EDF input.';
    log{end+1,1}='NOT TESTED: real-cohort exclusions or private manifest; real-cohort numerical output equivalence.';
    log{end+1,1}='NOT TESTED: LOO, refitted patient-cluster bootstrap, modifier LMMs, clinical rank tests, outcome eligibility, figure export.';
    log{end+1,1}='No expected clinical WTC means, F statistics, P values or patient counts were used as test targets.';
    log{end+1,1}='Passing checks does not establish biological validity or complete manuscript reproducibility.';
    if review
        log{2}='STATUS: REVIEW_REQUIRED';
        log{end+1,1}='All asserted checks completed, but MATLAB warnings require review.';
    else
        log{2}='STATUS: PASS';
    end
    writeLines(report,log);
    if isempty(localLog),localLog={'No fit warnings recorded.'};end
    writeLines(local,localLog);
catch ME
    log{2}='STATUS: FAIL';
    log{end+1,1}=['FAILED_STAGE: ' stage];
    log{end+1,1}=['ERROR_IDENTIFIER: ' ME.identifier];
    % Only this internally generated selection message is copied to the share
    % report; arbitrary exception messages and absolute paths remain local.
    if strcmp(ME.identifier,'CCGroupDemo:Selection')
        log{end+1,1}=['SELECTION_DETAIL: ' ME.message];
    end
    for j=1:min(5,numel(ME.stack))
        [~,baseName,ext]=fileparts(ME.stack(j).file);
        log{end+1,1}=sprintf('ERROR_LOCATION: %s%s | line %d', ...
            baseName,ext,ME.stack(j).line);
    end
    writeLines(report,log);
    localLog{end+1,1}=getReport(ME,'extended','hyperlinks','off');
    writeLines(local,localLog);
    fprintf(2,'\nStage-2 test stopped: %s\n',ME.message);
end
fprintf('\n%s\nReport: %s\n',log{2},report);
fprintf('Only generated synthetic data were used. No clinical sources were read.\n');
end

function checkSmallExamples()
T=table(["1";"1";"1";"1";"1";"1";"2";"2";"2";"2"], ...
    ["Pre";"Pre";"Pre";"Pre";"Post";"Post";"Pre";"Pre";"Post";"Post"], ...
    ["FT";"FT";"FT";"CP";"FT";"CP";"FT";"CP";"FT";"CP"], ...
    [0;30;60;0;300;300;0;0;300;300], ...
    [.2;.2;.2;.6;.2;.2;.8;.8;.8;.8], ...
    'VariableNames',{'CaseNo','State','Region','StartSec','Value'});
[V,Q,D]=cc_public_group_ops('summarize',T,'WTC','SyntheticUnit');
a=Q.Value(Q.CaseNo=="1"&Q.State=="Pre");
assert(abs(a-.4)<1e-12,'CCGroupDemo:RegionWeight','Regions must be equally weighted.');
p=D(string(D.State)=="Post",:);
assert(p.N_Normalized==2&&abs(p.MeanNormalized-75)<1e-10&&abs(p.SEMNormalized-25)<1e-10, ...
    'CCGroupDemo:Normalize','Patient normalization order failed.');
[~,~,Ddw]=cc_public_group_ops('summarize',T,'dwPLI','SyntheticUnit');
assert(all(isnan(Ddw.MeanNormalized)),'CCGroupDemo:DwpliRatio','dwPLI must not be normalized here.');
P=T([3 5 7 9],:);
R=cc_public_group_ops('match',P,T,'Unit');
assert(isequaln(R.Value,P.Value),'CCGroupDemo:Order','Matched values changed order.');
expectError(@() cc_public_group_ops('match',P,T([1:2 4:end],:),'Unit'),'CCMatched:MissingKey');
B=T;B.Value(3)=NaN;
expectError(@() cc_public_group_ops('match',P,B,'Unit'),'CCMatched:Nonfinite');
B=[T;T(1,:)];
expectError(@() cc_public_group_ops('keys',B),'CCEpochAudit:DuplicateEpochs');
assert(height(V)==8,'CCGroupDemo:Grouping','Unexpected grouped fixture count.');
end
function verifySelection(E,P,rules)
keys=cc_public_group_ops('keys',E);pk=cc_public_group_ops('keys',P);
assert(all(ismember(pk,keys)),'CCGroupDemo:Subset','Selected keys not in candidates.');
[G,c,s,r]=findgroups(E.CaseNo,E.State,E.Region);
for j=1:numel(c)
    a=find(G==j & ~E.RegionBad & isfinite(E.MeanWTC_4_13));
    if s(j)=="Pre"
        if numel(a)<rules.PreMin,a=[];else,[~,i]=sort(E.StartSec(a),'descend');a=a(i(1:rules.PreMin));end
    elseif s(j)=="Post"
        if numel(a)<rules.PostMin,a=[];else,[~,i]=sort(E.StartSec(a));a=a(i(1:min(rules.PostMax,numel(i))));end
    end
    got=P.StartSec(P.CaseNo==c(j)&P.State==s(j)&P.Region==r(j));
    expected=E.StartSec(a);
    % Compare the selected times, not the orientation of an empty index.
    % Do not use unique(): duplicated times or a changed count must still fail.
    assert(sameStartTimes(got,expected), ...
        'CCGroupDemo:Selection', ...
        ['Case=%s; State=%s; Region=%s; actual_n=%d; expected_n=%d; ' ...
         'actual_shape=%s; expected_shape=%s; actual_times=%s; expected_times=%s'], ...
        char(c(j)),char(s(j)),char(r(j)),numel(got),numel(expected), ...
        mat2str(size(got)),mat2str(size(expected)), ...
        mat2str(sort(got(:))'),mat2str(sort(expected(:))'));

end
end
function tf=sameStartTimes(a,b)
% Compare finite epoch start-time lists independent of row/column shape.
% Sorting was already part of the v2 test; (:) also handles 0-by-0 vs 0-by-1.
% This is test code only. The primary selector and its thresholds are unchanged.
tf=isequal(sort(a(:)),sort(b(:)));
end
function checkSelectionEdges()
% Deterministic test cases for zero-selection groups and exact boundaries.
% These are new artificial test inputs, not clinical data or study targets.
assert(sameStartTimes(zeros(0,1),[]),'CCGroupDemo:EmptyShape', ...
    'Empty selected-time lists should compare equal after column conversion.');
assert(sameStartTimes([60 30],[30;60]),'CCGroupDemo:VectorShape', ...
    'Non-empty selected-time lists should be shape-independent.');
assert(~sameStartTimes([],30)&&~sameStartTimes([30 60],[30 90])&& ...
    ~sameStartTimes([30 30],30),'CCGroupDemo:StrictTimeComparison', ...
    'Count, time or multiplicity mismatches must not be accepted.');
states=["Pre","Pre","Pre","Post","Post","Post", ...
    "Anterior","Posterior","Pre","Post"];
starts={0:30:240,0:30:270,0:30:330,750:30:780,750:30:810, ...
    750:30:1080,360:30:450,480:30:600,0:30:330,750:30:870};
expected={[],0:30:270,60:30:330,[],750:30:810,750:30:1020, ...
    [360 420 450],[480 510 570 600],[],[750 810 840]};
rows=cell(0,6);
for c=1:numel(states)
    for k=1:numel(starts{c})
        bad=(c==7&&k==2)||(c==9&&k<=3)||(c==10&&ismember(k,[2 5]));
        value=0.5;
        if c==8&&k==3,value=NaN;end
        rows(end+1,:)={string(920000+c),states(c),"FT",starts{c}(k),bad,value}; %#ok<AGROW>
    end
end
E=cell2table(rows,'VariableNames', ...
    {'CaseNo','State','Region','StartSec','RegionBad','MeanWTC_4_13'});
E.CaseNo=string(E.CaseNo);E.State=string(E.State);E.Region=string(E.Region);
E.RegionBad=logical(E.RegionBad);
rules=struct('PreMin',10,'PostMin',3,'PostMax',10);
P=cc_public_group_ops('select_primary',E,rules);
for c=1:numel(states)
    got=P.StartSec(P.CaseNo==string(920000+c));
    assert(sameStartTimes(got,expected{c}),'CCGroupDemo:SelectionBoundary', ...
        'Artificial boundary case %d selected unexpected times.',c);
end
verifySelection(E,P,rules);
% The repaired verifier must reject a row retained in an under-threshold group.
B=[P;E(1,:)];
expectError(@() verifySelection(E,B,rules),'CCGroupDemo:Selection');
% It must also reject an omitted valid epoch and the wrong temporal priority.
B=P;B(B.CaseNo=="920002"&B.StartSec==0,:)=[];
expectError(@() verifySelection(E,B,rules),'CCGroupDemo:Selection');
B=P;B.StartSec(B.CaseNo=="920003"&B.StartSec==60)=0;
expectError(@() verifySelection(E,B,rules),'CCGroupDemo:Selection');
% Infinite WTC is not converted to an empty/valid observation.
B=E;B.MeanWTC_4_13(1)=Inf;
expectError(@() cc_public_group_ops('select_primary',B,rules),'CCEpochAudit:WTC');
end
function Q=checkInference(m,label,n)
C=m.Coefficients;
[~,~,R]=fixedEffects(m,'DFMethod','residual');
[~,~,S]=fixedEffects(m,'DFMethod','satterthwaite');
assert(isequal(string(C.Name),string(R.Name))&&isequal(string(C.Name),string(S.Name)), ...
    'CCGroupDemo:CoefficientNames','Coefficient names differ by inference method.');
assert(max(abs(C.Estimate-R.Estimate))<1e-10 && max(abs(C.pValue-R.pValue))<1e-10, ...
    'CCGroupDemo:Residual','Saved coefficients do not match explicit residual inference.');
assert(all(R.DF==n-numel(R.Estimate)), ...
    'CCGroupDemo:ResidualDF','Residual DF differs from n minus number of fixed effects.');
assert(max(abs(R.Estimate-S.Estimate))<1e-10 && max(abs(R.SE-S.SE))<1e-10, ...
    'CCGroupDemo:SameModel','DF method changed estimate or SE.');
Q=table;
methods={'residual','satterthwaite'};stats={R,S};
for j=1:2
    A=stats{j};nr=numel(A.Estimate);
    assert(all(isfinite([A.Estimate;A.SE;A.DF;A.pValue;A.Lower;A.Upper]))&& ...
        all(A.SE>0)&&all(A.DF>0), 'CCGroupDemo:Inference','Invalid coefficient inference.');
    p=2*tcdf(-abs(A.Estimate./A.SE),A.DF);
    assert(max(abs(p-A.pValue))<1e-9,'CCGroupDemo:TTest','Explicit two-sided t-test mismatch.');
    T=table(repmat(string(label),nr,1),repmat(string(methods{j}),nr,1),string(A.Name), ...
        A.Estimate,A.SE,A.DF,A.pValue,A.Lower,A.Upper, ...
        'VariableNames',{'Model','DFMethod','Term','Estimate','SE','DF','P','CI_Lower','CI_Upper'});
    Q=append(Q,T);
end
end
function checkOmnibus(A)
assert(all(isfinite([A.FStat;A.DF1;A.DF2;A.P_Unadjusted]))&& ...
    all(A.DF1>0)&&all(A.DF2>0)&&all(A.P_Unadjusted>=0&A.P_Unadjusted<=1), ...
    'CCGroupDemo:Omnibus','Invalid omnibus model output.');
end
function checkContrasts(m,Q)
assert(height(Q)==4,'CCGroupDemo:Contrasts','Four contrasts required.');
assert(all(isfinite([Q.Estimate;Q.SE;Q.DF;Q.CI_Lower;Q.CI_Upper;Q.P_Unadjusted])), ...
    'CCGroupDemo:Contrasts','Invalid contrast output.');
C=m.Coefficients;i=find(string(C.Name)=="State_Post");
assert(numel(i)==1&&abs(Q.Estimate(4)-C.Estimate(i))<1e-10, ...
    'CCGroupDemo:ContrastDirection','Post-minus-Pre is inconsistent with reference coding.');
p=2*tcdf(-abs(Q.Estimate./Q.SE),Q.DF);
assert(max(abs(p-Q.P_Unadjusted))<1e-9,'CCGroupDemo:ContrastP','One-dimensional F/t correspondence failed.');
end
function checkBootstrapMeans(P,Q)
early=["Pre","Anterior","Posterior","Pre"];late=["Anterior","Posterior","Post","Post"];
for j=1:4
    a=P(P.State==early(j),:);b=P(P.State==late(j),:);
    [~,ia,ib]=intersect(a.CaseNo,b.CaseNo);
    delta=b.Value(ib)-a.Value(ia);delta=delta(isfinite(delta));
    assert(Q.N(j)==numel(delta)&&abs(Q.Estimate(j)-mean(delta))<1e-12, ...
        'CCGroupDemo:BootstrapPair','Paired-patient mean/N differs from explicit pairing.');
end
assert(all(isnan(Q.P_Unadjusted))&&all(isfinite(Q.CI_Lower))&& ...
    all(Q.CI_Upper>=Q.CI_Lower),'CCGroupDemo:BootstrapCI','Invalid bootstrap CI/P output.');
end
function expectError(fn,id)
caught=false;
try,fn();catch ME,caught=strcmp(ME.identifier,id);if ~caught,rethrow(ME);end,end
assert(caught,'CCGroupDemo:ExpectedFailure','An expected input rejection did not occur.');
end
function T=append(T,U)
if isempty(T),T=U;else,T=[T;U];end
end
function verifyManifest(root)
fid=fopen(fullfile(root,'SHA256SUMS.txt'),'r');
assert(fid>=0,'CCGroupDemo:Manifest','Manifest missing.');close=onCleanup(@() fclose(fid)); %#ok<NASGU>
n=0;
while true
    line=fgetl(fid);if ~ischar(line),break;end
    if isempty(strtrim(line)),continue;end
    t=regexp(line,'^([0-9a-f]{64})  ([A-Za-z0-9_./-]+)$','tokens','once');
    assert(~isempty(t)&&~startsWith(t{2},'/')&&~contains(t{2},'..'), ...
        'CCGroupDemo:Manifest','Invalid manifest entry.');
    f=fullfile(root,strrep(t{2},'/',filesep));
    assert(isfile(f)&&strcmp(fileSHA256(f),t{1}),'CCGroupDemo:Checksum','Package file differs: %s',t{2});n=n+1;
end
assert(n>=7,'CCGroupDemo:Manifest','Incomplete package.');
end
function h=fileSHA256(f)
fid=fopen(f,'rb');assert(fid>=0,'CCGroupDemo:Hash','Cannot read package file.');
g=onCleanup(@() fclose(fid)); %#ok<NASGU>
b=fread(fid,Inf,'*uint8');d=java.security.MessageDigest.getInstance('SHA-256');
d.update(typecast(b(:),'int8'));h=lower(reshape(dec2hex(typecast(d.digest(),'uint8'),2).',1,[]));
end
function tf=samePath(a,b)
a=strrep(char(a),'\','/');b=strrep(char(b),'\','/');
if ispc,tf=strcmpi(a,b);else,tf=strcmp(a,b);end
end
function writeLines(f,lines)
fid=fopen(f,'w','n','UTF-8');assert(fid>=0,'CCGroupDemo:Report','Cannot write report.');
g=onCleanup(@() fclose(fid)); %#ok<NASGU>
for k=1:numel(lines),fprintf(fid,'%s\n',lines{k});end
end
function restoreEnvironment(d,p,r)
if isfolder(d),cd(d);end
path(p);rng(r);
end
