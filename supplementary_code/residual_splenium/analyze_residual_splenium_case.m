function result = analyze_residual_splenium_case( ...
    caseFolder, studyID, residualStartSec, residualCompleteSec, ...
    config, channelMap, bipolarPairs, primaryElectrodes)
% ANALYZE_CC_CASE
% Corpus callosotomy intraoperative EEG analysis for one patient
%
% Pipeline:
%   EDF import
%   -> channel mapping
%   -> bipolar montage
%   -> artifact QC
%   -> Pre / Anterior / Posterior / Post epoch definition
%   -> resampling
%   -> 1-40 Hz filtering
%   -> WTC 4-13 Hz
%   -> COI exclusion
%   -> state × region summary
%
% Important:
% Raw EDF is never modified.

%% ============================================================
% 0. Configuration
% ============================================================

epochSec = config.epochSec;

allowedFs = config.allowedEDFsamplingRates;
fsTarget  = config.targetSamplingRate;

baselineSearchSec = config.baselineSearchWindowSec;
baselineNeedSec   = config.baselineCleanDurationSec;

postGuardSec  = config.postGuardSec;
postSearchSec = config.postSearchWindowSec;

artifactMaxAbs = config.artifactMaxAbs_uV;
artifactRange  = config.artifactRange_uV;
artifactFlatSD = config.artifactFlatSD_uV;

filterBand  = config.analysisFilterHz;
primaryBand = config.primaryFrequencyBandHz;

requiredCleanEpochs = config.minPreEpochs;
minPostEpochs       = config.minPostEpochs;
maxPostEpochs       = config.maxPostEpochs;

fprintf('Analysis version: %s\n',config.analysisVersion);

%% =========================================================
% 1. Event information
% Residual splenium completion surgery
% ==========================================================

if any(isnan([residualStartSec residualCompleteSec]))
    error('Study ID %.0f: residual disconnection timing is missing.',studyID);
end

if residualStartSec >= residualCompleteSec
    error('Study ID %.0f: event chronology is invalid.',studyID);
end

fprintf('\n========================================\n');
fprintf('Study ID: %.0f\n',studyID);
fprintf('Residual splenium start : %.0f s (%.2f min)\n', ...
    residualStartSec,residualStartSec/60);
fprintf('Residual splenium complete : %.0f s (%.2f min)\n', ...
    residualCompleteSec,residualCompleteSec/60);
fprintf('========================================\n');
%% ============================================================
% 2. EDF import
% ============================================================

if ~isfolder(caseFolder)
    error('Case folder does not exist: %s',caseFolder);
end

loaded = load_cc_edf(caseFolder,config);

labels = loaded.Labels;
fsRaw  = loaded.Fs;
dataRaw = loaded.Data;

% Physical dimensionsは最初のEDFから取得
info0 = edfinfo(loaded.FileQC.EDFPath{1});
units = string(info0.PhysicalDimensions);

fprintf('EDF sampling rate = %.0f Hz\n',fsRaw);
fprintf('Loaded samples     = %d\n',size(dataRaw,1));
fprintf('Loaded channels    = %d\n',size(dataRaw,2));

if ~any(abs(fsRaw - allowedFs) < 1e-6)
    error('Unexpected EDF sampling rate: %.0f Hz. Allowed: %s', ...
        fsRaw,mat2str(allowedFs));
end

%% ============================================================
% 3. Extract Nihon Kohden A-number
% ============================================================

nkLabels = strings(size(labels));

for i = 1:numel(labels)

    token = regexp(labels(i),'A\d+','match','once');

    if ~isempty(token)
        nkLabels(i) = string(token);
    else
        nkLabels(i) = "";
    end
end

% Only ordinary uV EEG channels
% Excludes POL $A11 / $A12 etc.
isEEG = units == "uV" & ~contains(labels,"$");

%% ============================================================
% 4. Convert EDF channels -> electrode data
% ============================================================

electrodeData = struct;

for i = 1:height(channelMap)

    nk = string(channelMap.NK_Channel(i));
    electrode = string(channelMap.Electrode(i));

    if ~ismember(electrode,primaryElectrodes)
        continue
    end

    idx = find(nkLabels == nk & isEEG);

    if numel(idx) ~= 1
        error('%s (%s) is not uniquely identified.', ...
            electrode,nk);
    end

   x = dataRaw(:,idx);

    electrodeData.(char(electrode)) = double(x);
end

recordDurationSec = loaded.DurationSec;

fprintf('Recording duration = %.2f min\n',recordDurationSec/60);

if residualCompleteSec > recordDurationSec
    error('Residual splenium completion is outside EDF recording.');
end

%% ============================================================
% 5. Bipolar montage
% ============================================================

bipolarData = struct;

for r = 1:height(bipolarPairs)

    region = char(bipolarPairs.Region(r));

    L1 = char(bipolarPairs.Left1(r));
    L2 = char(bipolarPairs.Left2(r));

    R1 = char(bipolarPairs.Right1(r));
    R2 = char(bipolarPairs.Right2(r));

    bipolarData.([region '_L']) = ...
        electrodeData.(L1) - electrodeData.(L2);

    bipolarData.([region '_R']) = ...
        electrodeData.(R1) - electrodeData.(R2);
end

%% =========================================================
% 6. Define candidate epochs
% Three states:
% Pre / Splenium / Post
% ==========================================================

candidateEpochs = table;

%% ---------- PRE ----------
preSearchStart = max(0, residualStartSec-baselineSearchSec);

% 30-s epochs aligned backward from residual disconnection start
preStarts = ...
    (residualStartSec-epochSec):-epochSec:preSearchStart;

preStarts = sort(preStarts);

if ~isempty(preStarts)

    tmp = table( ...
        repmat("Pre",numel(preStarts),1), ...
        (1:numel(preStarts))', ...
        preStarts', ...
        preStarts'/60, ...
        'VariableNames', ...
        {'State','StateEpoch','StartSec','StartMin'});

    candidateEpochs = [candidateEpochs;tmp];
end


%% ---------- SPLENIUM ----------
spleniumStarts = ...
    residualStartSec:epochSec:(residualCompleteSec-epochSec);

if ~isempty(spleniumStarts)

    tmp = table( ...
        repmat("Splenium",numel(spleniumStarts),1), ...
        (1:numel(spleniumStarts))', ...
        spleniumStarts', ...
        spleniumStarts'/60, ...
        'VariableNames', ...
        {'State','StateEpoch','StartSec','StartMin'});

    candidateEpochs = [candidateEpochs;tmp];
end


%% ---------- POST ----------
postStart = residualCompleteSec + postGuardSec;
postEnd = min(postStart+postSearchSec,recordDurationSec);

postStarts = ...
    postStart:epochSec:(postEnd-epochSec);

if ~isempty(postStarts)

    tmp = table( ...
        repmat("Post",numel(postStarts),1), ...
        (1:numel(postStarts))', ...
        postStarts', ...
        postStarts'/60, ...
        'VariableNames', ...
        {'State','StateEpoch','StartSec','StartMin'});

    candidateEpochs = [candidateEpochs;tmp];
end
%% ============================================================
% 7. Filter
% ============================================================

[b,a] = butter(4,filterBand/(fsTarget/2),'bandpass');

%% ============================================================
% 8. Epoch QC + WTC
% ============================================================

rows = {};

for e = 1:height(candidateEpochs)

    state = candidateEpochs.State(e);
    stateEpoch = candidateEpochs.StateEpoch(e);
    startSec = candidateEpochs.StartSec(e);

    i1 = round(startSec*fsRaw)+1;
    i2 = i1 + epochSec*fsRaw - 1;

    if i2 > numel(electrodeData.(char(primaryElectrodes(1))))
        continue
    end

    %% Electrode-level QC
    electrodeBad = struct;

    for ch = 1:numel(primaryElectrodes)

        elec = char(primaryElectrodes(ch));

        x = electrodeData.(elec);
        seg = x(i1:i2);

        p2p    = max(seg)-min(seg);
        sdVal  = std(seg);
        maxAbs = max(abs(seg));

        hardBad = ...
            maxAbs > artifactMaxAbs | ...
            p2p > artifactRange | ...
            sdVal < artifactFlatSD;

        electrodeBad.(elec) = hardBad;
    end

    %% Region-level analysis
    for r = 1:height(bipolarPairs)

        region = char(bipolarPairs.Region(r));

        elecs = { ...
            char(bipolarPairs.Left1(r)), ...
            char(bipolarPairs.Left2(r)), ...
            char(bipolarPairs.Right1(r)), ...
            char(bipolarPairs.Right2(r))};

        regionBad = ...
            electrodeBad.(elecs{1}) | ...
            electrodeBad.(elecs{2}) | ...
            electrodeBad.(elecs{3}) | ...
            electrodeBad.(elecs{4});

meanWTC = NaN;
meanDwPLI = NaN;
validFraction = NaN;
gapFlag = false;
numericBadCount = 0;
numericBadFraction = NaN;

if ~regionBad

            %% Bipolar
xL = bipolarData.([region '_L'])(i1:i2);
xR = bipolarData.([region '_R'])(i1:i2);

%% --------------------------------------------------------
% Missing-data / EDF-gap check
% --------------------------------------------------------
hasMissing = any(~isfinite(xL)) || any(~isfinite(xR));

if hasMissing

    gapFlag = true;
    meanWTC = NaN;
    validFraction = 0;
    numericBadCount = 0;
    numericBadFraction = NaN;

else

    %% Resample
    xL = resample(xL,fsTarget,fsRaw);
    xR = resample(xR,fsTarget,fsRaw);

    %% Zero-phase filter
    xL = filtfilt(b,a,double(xL));
    xR = filtfilt(b,a,double(xR));

%% Wavelet coherence
[wcoh,~,f,coi] = ...
    wcoherence(xL,xR,fsTarget);

%% Primary frequency band
bandMask = ...
    f >= primaryBand(1) & ...
    f <= primaryBand(2);

fBand = f(bandMask);
w = wcoh(bandMask,:);

%% COI mask
coiMask = fBand >= coi(:)';

%% Numerical sanity QC
% Count only points that belong to the actual analysis domain:
% 4-13 Hz AND inside the cone of influence
numericBadMask = ...
    ~isfinite(w) | ...
    w < 0 | ...
    w > 1;

numericBadCount = ...
    sum(numericBadMask & coiMask,'all');

numericCheckedCount = ...
    sum(coiMask,'all');

if numericCheckedCount > 0
    numericBadFraction = ...
        numericBadCount / numericCheckedCount;
else
    numericBadFraction = NaN;
end

% Invalid numerical values are treated as missing
w(numericBadMask) = NaN;

%% COI exclusion
w(~coiMask) = NaN;

%% Mean WTC
meanWTC = mean(w,'all','omitnan');

%% Fraction of analyzable points remaining
if numericCheckedCount > 0
    validFraction = ...
        sum(isfinite(w),'all') / numericCheckedCount;
else
    validFraction = 0;
end

%% Final sanity check
if ~isfinite(meanWTC) || meanWTC < 0 || meanWTC > 1
    meanWTC = NaN;
    validFraction = 0;
end

%% dwPLI robustness metric
[meanDwPLI, dwpliDetails] = calculate_dwpli( ...
    xL, ...
    xR, ...
    fsTarget, ...
    primaryBand);

% dwPLI may be slightly negative after debiasing.
% Only non-finite values are treated as missing.
if ~isfinite(meanDwPLI)
    meanDwPLI = NaN;
end
    end   % if hasMissing

end       % if ~regionBad

rows(end+1,:) = { ...
    studyID, ...
    char(state), ...
    stateEpoch, ...
    startSec, ...
    startSec/60, ...
    region, ...
    regionBad, ...
    gapFlag, ...
    numericBadCount, ...
    meanWTC, ...
    meanDwPLI, ...
    validFraction};

end       % for r

end       % for e

epochResults = cell2table(rows, ...
    'VariableNames', ...
    {'StudyID','State','StateEpoch','StartSec','StartMin', ...
     'Region','RegionBad','GapFlag','NumericBadCount', ...
     'MeanWTC_4_13','MeanDwPLI_4_13','ValidFraction'});
%% ============================================================
% 8b. Intrahemispheric WTC control
% Non-overlapping bipolar derivations
% Same epochs / preprocessing / frequency band as main WTC
% ============================================================

intraPairs = table( ...
    ["FT";"FT";"FT";"T";"T";"TO"], ...
    ["TO";"CP";"PO";"CP";"PO";"CP"], ...
    'VariableNames',{'Region1','Region2'});

intraRows = {};

% Number of raw samples
firstField = fieldnames(bipolarData);
nRawSamples = numel(bipolarData.(firstField{1}));

% Use exactly the epoch starts already generated in the main analysis
epochKeys = unique(epochResults(:,{'State','StateEpoch','StartSec'}), ...
    'rows','stable');

for e = 1:height(epochKeys)

    stateName = string(epochKeys.State(e));
    stateEpoch = epochKeys.StateEpoch(e);
    startSec = epochKeys.StartSec(e);

    % Same 30-sec raw-data interval
    i1 = round(startSec * fsRaw) + 1;
    i2 = i1 + round(epochSec * fsRaw) - 1;

    if i1 < 1 || i2 > nRawSamples
        continue
    end

    for p = 1:height(intraPairs)

        r1 = intraPairs.Region1(p);
        r2 = intraPairs.Region2(p);

        % ------------------------------------------------------
        % Use the existing region-level QC from the main pipeline
        % Both constituent regions must be usable
        % ------------------------------------------------------

        q1 = epochResults( ...
            string(epochResults.State) == stateName & ...
            epochResults.StateEpoch == stateEpoch & ...
            string(epochResults.Region) == r1, :);

        q2 = epochResults( ...
            string(epochResults.State) == stateName & ...
            epochResults.StateEpoch == stateEpoch & ...
            string(epochResults.Region) == r2, :);

        if isempty(q1) || isempty(q2)
            continue
        end

        pairBad = ...
            q1.RegionBad(1) || q2.RegionBad(1) || ...
            q1.GapFlag(1)  || q2.GapFlag(1);

        for hemi = ["L","R"]

            sig1Name = char(r1 + "_" + hemi);
            sig2Name = char(r2 + "_" + hemi);

            meanIntraWTC = NaN;
            validFractionIntra = 0;

            if ~pairBad

                x1 = bipolarData.(sig1Name)(i1:i2);
                x2 = bipolarData.(sig2Name)(i1:i2);

                % Missing-data / EDF-gap check
                hasMissing = ...
                    any(~isfinite(x1)) || ...
                    any(~isfinite(x2));

                if ~hasMissing

                    %% Same resampling as main analysis
                    x1 = resample(x1,fsTarget,fsRaw);
                    x2 = resample(x2,fsTarget,fsRaw);

                    %% Same zero-phase filter as main analysis
                    x1 = filtfilt(b,a,double(x1));
                    x2 = filtfilt(b,a,double(x2));

                    %% Wavelet coherence
                    [wcohIntra,~,fIntra,coiIntra] = ...
                        wcoherence(x1,x2,fsTarget);

                    %% Same primary band
                    bandMaskIntra = ...
                        fIntra >= primaryBand(1) & ...
                        fIntra <= primaryBand(2);

                    fBandIntra = fIntra(bandMaskIntra);
                    wIntra = wcohIntra(bandMaskIntra,:);

                    %% Numerical sanity QC
                    numericBadMask = ...
                        ~isfinite(wIntra) | ...
                        wIntra < 0 | ...
                        wIntra > 1;

                    wIntra(numericBadMask) = NaN;

                    %% Same cone-of-influence exclusion
                    coiMaskIntra = fBandIntra >= coiIntra(:)';
                    wIntra(~coiMaskIntra) = NaN;

                    %% Mean WTC
                    meanIntraWTC = mean(wIntra,'all','omitnan');

                    validFractionIntra = ...
                        sum(isfinite(wIntra),'all') / numel(wIntra);

                    if ~isfinite(meanIntraWTC) || ...
                            meanIntraWTC < 0 || meanIntraWTC > 1

                        meanIntraWTC = NaN;
                        validFractionIntra = 0;
                    end
                end
            end

            intraRows(end+1,:) = { ...
                studyID, ...
                char(stateName), ...
                stateEpoch, ...
                startSec, ...
                startSec/60, ...
                char(r1), ...
                char(r2), ...
                char(hemi), ...
                pairBad, ...
                meanIntraWTC, ...
                validFractionIntra};

        end
    end
end

%% Convert to table

if isempty(intraRows)

    intraEpochResults = table;

else

    intraEpochResults = cell2table( ...
        intraRows, ...
        'VariableNames', ...
        {'StudyID','State','StateEpoch','StartSec','StartMin', ...
         'Region1','Region2','Hemisphere','PairBad', ...
         'MeanIntraWTC_4_13','ValidFraction'});
end
%% ============================================================
% 9. Select Pre and Post 5-min representative epochs
% ============================================================

selected = table;

regions = string(bipolarPairs.Region);

for r = 1:numel(regions)

    region = regions(r);

    %% PRE
    tmp = epochResults( ...
        string(epochResults.State)=="Pre" & ...
        string(epochResults.Region)==region & ...
        ~epochResults.RegionBad & ...
        ~isnan(epochResults.MeanWTC_4_13),:);

    % closest to anterior start first
    tmp = sortrows(tmp,'StartSec','descend');

    if height(tmp) >= requiredCleanEpochs

        tmp = tmp(1:requiredCleanEpochs,:);
        tmp = sortrows(tmp,'StartSec','ascend');

        selected = [selected;tmp];
    end

    %% POST
   tmp = epochResults( ...
    string(epochResults.State)=="Post" & ...
    string(epochResults.Region)==region & ...
    ~epochResults.RegionBad & ...
    ~isnan(epochResults.MeanWTC_4_13),:);

tmp = sortrows(tmp,'StartSec','ascend');

% Postは記録終了までの利用可能なclean epochを使用
% 最低3 epochs = 1.5 min

if height(tmp) >= minPostEpochs

    % 最大10 epochs = 5 min
    nTake = min(height(tmp),maxPostEpochs);

    tmp = tmp(1:nTake,:);

    selected = [selected;tmp];
end
end

%% ============================================================
% 10. Data for state summary
% ============================================================

% Pre/Post: representative clean epochs
% Splenium: all usable epochs

prePost = selected;

intra = epochResults( ...
    string(epochResults.State) == "Splenium" & ...
    ~epochResults.RegionBad & ...
    ~isnan(epochResults.MeanWTC_4_13),:);

analysisEpochs = [prePost;intra];

%% ============================================================
% 11. State × region summary
% ============================================================

if isempty(analysisEpochs)

    stateSummary = table;

else

    stateSummary = groupsummary( ...
    analysisEpochs, ...
    {'State','Region'}, ...
    {'mean','std','median'}, ...
    {'MeanWTC_4_13','MeanDwPLI_4_13'});
end
%% dwPLI State x region summary

analysisEpochs_dwpli = analysisEpochs( ...
    isfinite(analysisEpochs.MeanDwPLI_4_13),:);

if isempty(analysisEpochs_dwpli)

    stateSummary_dwpli = table;

else

    stateSummary_dwpli = groupsummary( ...
        analysisEpochs_dwpli, ...
        {'State','Region'}, ...
        {'mean','std','median'}, ...
        'MeanDwPLI_4_13');

end
%% ============================================================
% 12. QC availability summary
% ============================================================

availabilityRows = {};

states = ["Pre","Splenium","Post"];

for s = 1:numel(states)

    for r = 1:numel(regions)

        tmp = epochResults( ...
            string(epochResults.State)==states(s) & ...
            string(epochResults.Region)==regions(r),:);

        nCandidate = height(tmp);

        nGood = sum( ...
            ~tmp.RegionBad & ...
            ~isnan(tmp.MeanWTC_4_13));

        availabilityRows(end+1,:) = { ...
            char(states(s)), ...
            char(regions(r)), ...
            nCandidate, ...
            nGood};
    end
end

availability = cell2table(availabilityRows, ...
    'VariableNames', ...
    {'State','Region','CandidateEpochs','UsableEpochs'});
%% ============================================================
% Intrahemispheric State summary
% Matched Pre/Post timing to primary WTC analysis
% ============================================================

validIntraMatched = table;

if isempty(intraEpochResults)

    intraStateSummary = table;

else
    % Start with finite intrahemispheric WTC only
    validIntra = intraEpochResults( ...
        isfinite(intraEpochResults.MeanIntraWTC_4_13), :);

    % --------------------------------------------------------
    % PRE:
    % use only StartSec values represented in primary selected
    % Pre epochs
    % --------------------------------------------------------

    selectedPreStarts = unique( ...
        selected.StartSec(string(selected.State) == "Pre"));

    keepPre = ...
        string(validIntra.State) == "Pre" & ...
        ismember(validIntra.StartSec,selectedPreStarts);

    % --------------------------------------------------------
    % POST:
    % use only StartSec values represented in primary selected
    % Post epochs
    % --------------------------------------------------------

    selectedPostStarts = unique( ...
        selected.StartSec(string(selected.State) == "Post"));

    keepPost = ...
        string(validIntra.State) == "Post" & ...
        ismember(validIntra.StartSec,selectedPostStarts);

    % --------------------------------------------------------
   % Splenium:
% primary analysis uses all usable epochs
    % --------------------------------------------------------

keepIntraoperative = ...
    string(validIntra.State) == "Splenium";

    % Final matched dataset
    validIntraMatched = validIntra( ...
        keepPre | keepIntraoperative | keepPost, :);

    if isempty(validIntraMatched)

        intraStateSummary = table;

    else

        intraStateSummary = groupsummary( ...
            validIntraMatched, ...
            {'State','Region1','Region2','Hemisphere'}, ...
            {'mean','std','median'}, ...
            'MeanIntraWTC_4_13');

    end
end

%% ============================================================
% Exact time-matched Inter vs Intra WTC control
% Same patient / State / StartSec
% ============================================================

matchedConnectionSummary = table;

statesMatched = ["Pre","Splenium","Post"];

matchedRows = {};

for s = 1:numel(statesMatched)

    st = statesMatched(s);

    %% --------------------------------------------------------
    % Determine eligible timestamps
    % ---------------------------------------------------------

    if st == "Pre" || st == "Post"

        % Primary-analysis selected timestamps
        primaryStarts = unique( ...
            selected.StartSec(string(selected.State) == st));

    else

       % Splenium:
% all timestamps generated in primary analysis
        primaryStarts = unique( ...
            epochResults.StartSec(string(epochResults.State) == st));

    end

    %% Finite interhemispheric epochs

    tmpInter = epochResults( ...
        string(epochResults.State) == st & ...
        isfinite(epochResults.MeanWTC_4_13) & ...
        ismember(epochResults.StartSec,primaryStarts), :);

    %% Finite intrahemispheric epochs

    tmpIntra = intraEpochResults( ...
        string(intraEpochResults.State) == st & ...
        isfinite(intraEpochResults.MeanIntraWTC_4_13) & ...
        ismember(intraEpochResults.StartSec,primaryStarts), :);

    %% Exact common timestamps

    interStarts = unique(tmpInter.StartSec);
    intraStarts = unique(tmpIntra.StartSec);

    commonStarts = intersect(interStarts,intraStarts);

    %% --------------------------------------------------------
    % At each identical 30-sec timestamp:
    % calculate one Inter mean and one Intra mean
    % ---------------------------------------------------------

    for k = 1:numel(commonStarts)

        ss = commonStarts(k);

        xInter = tmpInter.MeanWTC_4_13( ...
            tmpInter.StartSec == ss);

        xIntra = tmpIntra.MeanIntraWTC_4_13( ...
            tmpIntra.StartSec == ss);

        xInter = xInter(isfinite(xInter));
        xIntra = xIntra(isfinite(xIntra));

        if isempty(xInter) || isempty(xIntra)
            continue
        end

        meanInter = mean(xInter);
        meanIntra = mean(xIntra);

        matchedRows(end+1,:) = { ...
            studyID, char(st), ss, ...
            meanInter, meanIntra, ...
            numel(xInter), numel(xIntra)};
    end
end

if ~isempty(matchedRows)

    matchedConnectionSummary = cell2table( ...
        matchedRows, ...
        'VariableNames', ...
        {'StudyID','State','StartSec', ...
        'InterWTC','IntraWTC', ...
        'NInterConnections','NIntraConnections'});
end

%% ============================================================
% 13. Output
% ============================================================

result = struct;

result.StudyID = studyID;

result.Events = struct( ...
    'ResidualSpleniumStartSec',residualStartSec, ...
    'ResidualSpleniumCompleteSec',residualCompleteSec);

result.SamplingRateRaw = fsRaw;
result.SamplingRateProcessed = fsTarget;

result.EpochResults = epochResults;
result.IntraEpochResults = intraEpochResults;
result.IntraMatchedEpochResults = validIntraMatched;
result.IntraStateSummary = intraStateSummary;
result.MatchedConnectionSummary = matchedConnectionSummary;
result.SelectedPrePost = selected;
result.AnalysisEpochs = analysisEpochs;
result.StateSummary = stateSummary;
result.StateSummaryDwPLI = stateSummary_dwpli;
result.Availability = availability;

fprintf('\nAnalysis complete: Study ID %.0f\n',studyID);

end

