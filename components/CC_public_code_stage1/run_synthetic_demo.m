function outDir = run_synthetic_demo()
%RUN_SYNTHETIC_DEMO Exercise supplied per-recording functions on new artificial EDFs.
% Stage-1 validation candidate, NOT the full manuscript reproduction package.
% No input arguments: real EDFs, clinical spreadsheets and CORE MATs cannot be
% selected by this entry point. No source .m file or study result is overwritten.
% New fixtures and reports are created below this package's output directory.
% The caller's working directory and MATLAB path are restored on exit.
% This NEW harness has not been runtime-tested in MATLAB by its authoring system.

packageDir = fileparts(mfilename('fullpath'));
outParent = fullfile(packageDir,'output');
if ~isfolder(outParent), mkdir(outParent); end
outDir = tempname(outParent);
[ok,msg] = mkdir(outDir);
if ~ok, error('CCDemo:Output','Cannot create new output: %s',msg); end
oldDir = pwd;
oldPath = path;
envGuard = onCleanup(@() restoreEnvironment(oldDir,oldPath)); %#ok<NASGU>
log = {'CC PUBLIC CODE - STAGE 1 SYNTHETIC TEST'; ...
    'STATUS: IN_PROGRESS'; ...
    ['MATLAB: ' version]; ...
    'Only newly generated artificial signals are analysed.'; ...
    'This is not a reproduction of the 32-patient clinical results.'};
reportFile = fullfile(outDir,'SHARE_DEMO_REPORT.txt');
writeLines(reportFile,log);
stage = 'setup';
try
    % Prevent a research-folder copy of a same-named function from taking precedence.
    srcDir = fullfile(packageDir,'src');
    toolsDir = fullfile(packageDir,'tools');
    cd(srcDir);
    addpath(packageDir,'-begin');
    addpath(toolsDir,'-begin');
    addpath(srcDir,'-begin');
    clear analyze_cc_case analyze_cc_case_multiband analyze_cc_case_signalmetrics
    clear calculate_dwpli load_cc_edf check_multifile_continuity
    clear cc_demo_configuration cc_demo_make_recording cc_demo_write_edf
    rehash;
    verifyManifest(packageDir);
    sourceNames = {'analyze_cc_case','analyze_cc_case_multiband', ...
        'analyze_cc_case_signalmetrics','calculate_dwpli', ...
        'load_cc_edf','check_multifile_continuity','channel_map'};
    for k=1:numel(sourceNames)
        expected = fullfile(srcDir,[sourceNames{k} '.m']);
        assert(samePath(which(sourceNames{k}),expected), ...
            'CCDemo:Shadowing','A bundled source function is shadowed.');
    end
    toolNames = {'cc_demo_configuration','cc_demo_make_recording','cc_demo_write_edf'};
    for k=1:numel(toolNames)
        assert(samePath(which(toolNames{k}),fullfile(toolsDir,[toolNames{k} '.m'])), ...
            'CCDemo:Shadowing','A bundled test utility is shadowed.');
    end
    deps = {'edfheader','edfwrite','edfinfo','edfread','wcoherence', ...
        'resample','butter','filtfilt','hann','bandpower','groupsummary'};
    for k=1:numel(deps)
        loc = which(deps{k});
        assert(~isempty(loc),'CCDemo:Dependency','Required function is missing: %s',deps{k});
        assert(startsWith(lower(strrep(loc,'\','/')), ...
            lower(strrep(matlabroot,'\','/'))), 'CCDemo:ToolboxShadowing', ...
            'A MathWorks dependency is shadowed: %s',deps{k});
    end
    versions = ver;
    for k=1:numel(versions)
        if any(strcmp(versions(k).Name, ...
                {'MATLAB','Signal Processing Toolbox','Wavelet Toolbox'}))
            log{end+1,1} = sprintf('PRODUCT: %s | %s', ...
                versions(k).Name,versions(k).Version); %#ok<AGROW>
        end
    end
    log{end+1,1} = 'PASS: package checksums and function resolution';
    writeLines(reportFile,log);

    stage = 'synthetic EDF continuity fixtures';
    cfg = cc_demo_configuration();
    checkSyntheticBoundaries(outDir,cfg);
    log{end+1,1} = 'PASS: synthetic EDF small-overlap trimming and positive-gap preservation';
    writeLines(reportFile,log);

    stage = 'dwPLI edge-case tests';
    checkDwpliEdges();
    log{end+1,1} = 'PASS: dwPLI missing values, short input, zero denominator, unequal lengths and symmetry';
    writeLines(reportFile,log);

    stage = 'synthetic recording generation';
    inputDir = fullfile(outDir,'synthetic_input');
    mkdir(inputDir);
    [eventRow,fixture] = cc_demo_make_recording(inputDir);
    run(fullfile(srcDir,'channel_map.m'));
    qc = check_multifile_continuity(inputDir);
    assert(height(qc)==2 && all(qc.SamplingRateHz==fixture.Fs), ...
        'CCDemo:MainHeader','Unexpected synthetic EDF count or sampling rate.');
    assert(qc.GapFromPreviousSec(2)==0, ...
        'CCDemo:MainContinuity','Synthetic main files are not contiguous.');
    log{end+1,1} = 'PASS: two artificial EDFs with fixed fictional headers';
    log{end+1,1} = 'FIXTURE: 500 Hz, 630 s, 16 channels, event offsets 330/360/390 s';
    writeLines(reportFile,log);

    stage = 'primary WTC and exact-time per-recording pipeline';
    fprintf('\n[1/3] Running supplied primary per-recording code on synthetic EDFs...\n');
    timer = tic;
    R = analyze_cc_case(inputDir,eventRow,cfg,channelMap,bipolarPairs,primaryElectrodes);
    checkResult(R,cfg);
    log{end+1,1} = sprintf('PASS: primary WTC / dwPLI / exact-time | %.1f s',toc(timer));
    log{end+1,1} = sprintf('SYNTHETIC COUNTS: epoch-region=%d; selected=%d; summaries=%d; exact times=%d', ...
        height(R.EpochResults),height(R.AnalysisEpochs), ...
        height(R.StateSummary),height(R.MatchedConnectionSummary));
    writeLines(reportFile,log);

    stage = 'multiband per-recording pipeline';
    fprintf('\n[2/3] Running supplied frequency-band code on the same synthetic EDFs...\n');
    timer = tic;
    M = analyze_cc_case_multiband(inputDir,eventRow,cfg,channelMap,bipolarPairs,primaryElectrodes);
    checkResult(M,cfg);
    checkSharedOutputs(R,M);
    bands = {'MeanWTC_Delta','MeanWTC_Theta','MeanWTC_Alpha','MeanWTC_Beta'};
    for k=1:numel(bands)
        v = M.AnalysisEpochs.(bands{k});
        assert(all(isfinite(v) & v>=0 & v<=1), ...
            'CCDemo:BandRange','Invalid synthetic band WTC.');
    end
    log{end+1,1} = sprintf('PASS: multiband calculations and common-output agreement | %.1f s',toc(timer));
    writeLines(reportFile,log);

    stage = 'signal-metrics per-recording pipeline';
    fprintf('\n[3/3] Running supplied signal-metrics code on the same synthetic EDFs...\n');
    timer = tic;
    S = analyze_cc_case_signalmetrics(inputDir,eventRow,cfg,channelMap,bipolarPairs,primaryElectrodes);
    checkResult(S,cfg);
    checkSharedOutputs(R,S);
    metrics = {'MeanRMS','MeanSD','MeanPower4_13','MeanPower1_40','RelativePower4_13'};
    for k=1:numel(metrics)
        v = S.AnalysisEpochs.(metrics{k});
        assert(all(isfinite(v) & v>0),'CCDemo:SignalRange','Invalid synthetic signal metric.');
    end
    assert(all(S.AnalysisEpochs.RelativePower4_13<=1+1e-10), ...
        'CCDemo:RelativePower','Relative band power exceeds its broadband denominator.');
    log{end+1,1} = sprintf('PASS: signal metrics and common-output agreement | %.1f s',toc(timer));
    writeLines(reportFile,log);

    stage = 'synthetic-only summaries';
    summary = syntheticSummary(R,M,S);
    disp(summary);
    % New synthetic results only. No real patient table/model is ever exported.
    writetable(summary,fullfile(outDir,'SYNTHETIC_ONLY_state_summary.csv'));
    log{end+1,1} = 'PASS: synthetic-only summary export';
    log{end+1,1} = 'NOT TESTED: 1000/2000-Hz input, all possible artefacts or missing-data patterns.';
    log{end+1,1} = 'NOT TESTED: final cohort technical exclusions, cohort-level matching, LMMs, bootstrap or clinical analyses.';
    log{end+1,1} = 'No expected clinical WTC means, F statistics, P values or patient counts were used as test targets.';
    log{end+1,1} = 'Passing this smoke test does not establish biological validity or complete manuscript reproducibility.';
    log{2} = 'STATUS: PASS';
    writeLines(reportFile,log);
    fprintf('\nSYNTHETIC DEMO: PASS\nReport: %s\n',reportFile);
catch ME
    log{2} = 'STATUS: FAIL';
    log{end+1,1} = ['FAILED_STAGE: ' stage];
    log{end+1,1} = ['ERROR_IDENTIFIER: ' ME.identifier];
    % No exception message / full local path is copied into the shareable report.
    for k=1:min(5,numel(ME.stack))
        [~,base,ext] = fileparts(ME.stack(k).file);
        log{end+1,1} = sprintf('STACK: %s%s | line %d',base,ext,ME.stack(k).line); %#ok<AGROW>
    end
    log{end+1,1} = 'Do not alter thresholds or bypass a failing test. Review this failure before proceeding.';
    writeLines(reportFile,log);
    writeLines(fullfile(outDir,'LOCAL_DIAGNOSTICS.txt'), ...
        {getReport(ME,'extended','hyperlinks','off')});
    fprintf(2,'\nSYNTHETIC DEMO: FAIL at %s\n%s\n',stage,ME.message);
    fprintf('Report: %s\n',reportFile);
end
end

function checkResult(R,cfg)
assert(R.SamplingRateRaw==500 && R.SamplingRateProcessed==200, ...
    'CCDemo:Sampling','Unexpected synthetic sampling rates.');
E = R.EpochResults;
assert(height(E)==85 && height(R.AnalysisEpochs)==80 && height(R.StateSummary)==20, ...
    'CCDemo:Counts','Unexpected synthetic epoch/aggregation count.');
assert(all(~E.RegionBad & ~E.GapFlag),'CCDemo:FixtureQC','Unexpected rejection of clean synthetic data.');
assert(all(isfinite(E.MeanWTC_4_13) & E.MeanWTC_4_13>=0 & E.MeanWTC_4_13<=1), ...
    'CCDemo:WTCRange','Synthetic primary WTC is invalid.');
assert(all(isfinite(E.MeanDwPLI_4_13)), 'CCDemo:DwpliFinite','Synthetic dwPLI is non-finite.');
regions = ["FT","T","TO","CP","PO"];
for reg=regions
    P = R.SelectedPrePost(string(R.SelectedPrePost.Region)==reg,:);
    pre = P.StartSec(string(P.State)=="Pre");
    post = P.StartSec(string(P.State)=="Post");
    assert(isequal(sort(pre(:)),(30:30:300)'), ...
        'CCDemo:PreSelection','Pre selection did not retain the closest 10 epochs.');
    assert(isequal(sort(post(:)),(510:30:600)'), ...
        'CCDemo:PostSelection','Unexpected synthetic Post selection.');
    assert(numel(pre)==cfg.minPreEpochs && numel(post)>=cfg.minPostEpochs && ...
        numel(post)<=cfg.maxPostEpochs,'CCDemo:SelectionRule','Selection rule violation.');
end
X = R.MatchedConnectionSummary;
assert(height(X)==16,'CCDemo:ExactCount','Unexpected exact-time row count.');
assert(height(unique(X(:,{'State','StartSec'}),'rows'))==height(X), ...
    'CCDemo:ExactDuplicates','Duplicate exact-time key.');
assert(all(isfinite(X.InterWTC) & isfinite(X.IntraWTC)), ...
    'CCDemo:ExactFinite','Non-finite paired WTC.');
assert(all(X.NInterConnections==5 & X.NIntraConnections==12), ...
    'CCDemo:Connections','Unexpected synthetic connection coverage.');
end

function checkSharedOutputs(A,B)
keys = {'State','Region','StartSec'};
for field = {'EpochResults','AnalysisEpochs'}
    x = sortrows(A.(field{1}),keys);
    y = sortrows(B.(field{1}),keys);
    assert(isequal(string(x.State),string(y.State)) && ...
        isequal(string(x.Region),string(y.Region)) && isequal(x.StartSec,y.StartSec), ...
        'CCDemo:SharedKeys','Per-recording variants selected different synthetic keys.');
    for col = {'MeanWTC_4_13','MeanDwPLI_4_13'}
        u = x.(col{1}); v = y.(col{1});
        assert(isequal(isfinite(u),isfinite(v)), ...
            'CCDemo:SharedFinite','Finite masks differ between per-recording variants.');
        ok = isfinite(u);
        assert(all(abs(u(ok)-v(ok))<=1e-10), ...
            'CCDemo:SharedValues','Common per-recording metrics differ.');
    end
end
end

function T = syntheticSummary(R,M,S)
states = ["Pre";"Anterior";"Posterior";"Post"];
values = zeros(4,9);
for k=1:4
    r = R.AnalysisEpochs(string(R.AnalysisEpochs.State)==states(k),:);
    m = M.AnalysisEpochs(string(M.AnalysisEpochs.State)==states(k),:);
    s = S.AnalysisEpochs(string(S.AnalysisEpochs.State)==states(k),:);
    values(k,:) = [mean(r.MeanWTC_4_13),mean(r.MeanDwPLI_4_13), ...
        mean(m.MeanWTC_Delta),mean(m.MeanWTC_Theta),mean(m.MeanWTC_Alpha), ...
        mean(m.MeanWTC_Beta),mean(s.MeanRMS),mean(s.MeanPower1_40), ...
        mean(s.RelativePower4_13)];
end
T = [table(states,'VariableNames',{'SyntheticState'}), ...
    array2table(values,'VariableNames',{'WTC','dwPLI','Delta','Theta','Alpha', ...
    'Beta','RMS','BroadbandPower','RelativePower'})];
end

function checkDwpliEdges()
fs = 200;
rs = RandStream('mt19937ar','Seed',710);
x = randn(rs,6000,1); y = randn(rs,6000,1);
[a,d] = calculate_dwpli(x,y,fs,[4 13]);
b = calculate_dwpli(y,x,fs,[4 13]);
assert(isfinite(a) && isfinite(b) && abs(a-b)<1e-10, ...
    'CCDemo:DwpliSymmetry','dwPLI signal-exchange symmetry failed.');
assert(d.NumberOfSegments==29 && d.WindowSec==2 && d.OverlapFraction==0.5, ...
    'CCDemo:DwpliSegments','Unexpected 30-s spectral segmentation.');
xMissing = x; xMissing(1) = NaN;
assert(isnan(calculate_dwpli(xMissing,y,fs,[4 13])), ...
    'CCDemo:DwpliMissing','Missing-input behaviour differs from the supplied code.');
assert(isnan(calculate_dwpli(x(1:200),y(1:200),fs,[4 13])), ...
    'CCDemo:DwpliShort','Short-input behaviour differs from the supplied code.');
assert(isnan(calculate_dwpli(zeros(6000,1),zeros(6000,1),fs,[4 13])), ...
    'CCDemo:DwpliZero','Zero-denominator behaviour differs from the supplied code.');
threw = false;
try
    calculate_dwpli(x,y(1:end-1),fs,[4 13]);
catch
    threw = true;
end
assert(threw,'CCDemo:DwpliLength','Unequal-length input was not rejected.');
end

function checkSyntheticBoundaries(outDir,cfg)
fs = 500;
t = (0:4*fs-1)'/fs;
A = [10*sin(2*pi*7*t),9*cos(2*pi*9*t)];
B = [11*cos(2*pi*6*t),8*sin(2*pi*8*t)];
root = fullfile(outDir,'synthetic_boundary_tests');
mkdir(root);
for kind = {'overlap','gap'}
    d = fullfile(root,kind{1}); mkdir(d);
    cc_demo_write_edf(fullfile(d,'part01.edf'),A,fs,0);
    if strcmp(kind{1},'overlap'), start = 3; else, start = 5; end
    cc_demo_write_edf(fullfile(d,'part02.edf'),B,fs,start);
    Z = load_cc_edf(d,cfg);
    if strcmp(kind{1},'overlap')
        assert(size(Z.Data,1)==7*fs && all(isfinite(Z.Data),'all'), ...
            'CCDemo:Overlap','Small-overlap sample count/finite check failed.');
    else
        gap = Z.Data(4*fs+1:5*fs,:);
        assert(size(Z.Data,1)==9*fs && all(isnan(gap),'all'), ...
            'CCDemo:Gap','Positive-gap padding check failed.');
        assert(all(isfinite(Z.Data(1:4*fs,:)),'all') && ...
            all(isfinite(Z.Data(5*fs+1:end,:)),'all'), ...
            'CCDemo:GapEdges','Unexpected missing values outside synthetic gap.');
    end
end
end

function verifyManifest(root)
fid = fopen(fullfile(root,'SHA256SUMS.txt'),'r');
assert(fid>=0,'CCDemo:Manifest','Package checksum manifest is missing.');
g = onCleanup(@() fclose(fid)); %#ok<NASGU>
n = 0;
while true
    line = fgetl(fid);
    if ~ischar(line), break; end
    if isempty(strtrim(line)), continue; end
    parts = regexp(line,'^([0-9a-f]{64})  ([A-Za-z0-9_./-]+)$','tokens','once');
    assert(~isempty(parts),'CCDemo:ManifestFormat','Unexpected manifest format.');
    rel = parts{2};
    assert(~startsWith(rel,'/') && ~contains(rel,'..'), ...
        'CCDemo:ManifestPath','Unexpected manifest path.');
    f = fullfile(root,strrep(rel,'/',filesep));
    assert(isfile(f) && strcmp(fileSHA256(f),parts{1}), ...
        'CCDemo:Checksum','Package file is missing or changed: %s',rel);
    n = n+1;
end
assert(n>=11,'CCDemo:ManifestCount','Incomplete checksum manifest.');
end

function h = fileSHA256(fileName)
fid = fopen(fileName,'rb');
assert(fid>=0,'CCDemo:HashOpen','Cannot read a package file.');
g = onCleanup(@() fclose(fid)); %#ok<NASGU>
bytes = fread(fid,Inf,'*uint8');
md = java.security.MessageDigest.getInstance('SHA-256');
md.update(typecast(bytes(:),'int8'));
h = lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
end

function tf = samePath(a,b)
a = strrep(char(a),'\','/'); b = strrep(char(b),'\','/');
if ispc, tf=strcmpi(a,b); else, tf=strcmp(a,b); end
end

function writeLines(f,lines)
fid = fopen(f,'w','n','UTF-8');
assert(fid>=0,'CCDemo:Report','Cannot write report.');
g = onCleanup(@() fclose(fid)); %#ok<NASGU>
for k=1:numel(lines), fprintf(fid,'%s\n',lines{k}); end
end

function restoreEnvironment(d,p)
if isfolder(d), cd(d); end
path(p);
end
