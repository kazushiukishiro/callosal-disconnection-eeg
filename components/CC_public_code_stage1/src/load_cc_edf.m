function out = load_cc_edf(caseFolder, config)
% LOAD_CC_EDF
% 1～複数EDFを実時間順に読み込み、連続timelineとして保持する
%
% Rules:
%   abs(gap) <= 2 s : header roundingとして連続扱い
%   gap > 2 s       : NaNを挿入して実時間gapを保持
%   overlap < -2 s  : error
%   channel mismatch: error
%
% Output:
%   out.Data        : samples x channels
%   out.Fs          : raw sampling rate
%   out.Labels      : channel labels
%   out.TimeSec     : recording startからの秒
%   out.FileQC      : EDF boundary QC
%   out.SourceFiles : 使用EDF一覧

edfFiles = dir(fullfile(caseFolder,'*.edf'));

if isempty(edfFiles)
    error('EDF file not found: %s',caseFolder);
end

%% ------------------------------------------------------------
% 1. Header QC
% ------------------------------------------------------------

qc = check_multifile_continuity(caseFolder);

% 時刻順になっている前提
nFiles = height(qc);

%% ------------------------------------------------------------
% 2. Sampling rate / channel consistency
% ------------------------------------------------------------

fsAll = qc.SamplingRateHz;

if numel(unique(fsAll)) ~= 1
    error('Sampling rates differ within one case.');
end

fsRaw = fsAll(1);

if ~ismember(fsRaw,config.allowedEDFsamplingRates)
    error('Unsupported EDF sampling rate: %.0f Hz',fsRaw);
end

infoRef = edfinfo(qc.EDFPath{1});
labelsRef = string(infoRef.SignalLabels);

for k = 2:nFiles

    infoK = edfinfo(qc.EDFPath{k});
    labelsK = string(infoK.SignalLabels);

    if ~isequal(labelsRef,labelsK)
        error('Channel labels differ between EDF files.');
    end
end

%% ------------------------------------------------------------
% 3. Boundary check
% ------------------------------------------------------------

for k = 2:nFiles

    gapSec = qc.GapFromPreviousSec(k);

    if gapSec < -2
        error( ...
            'Large EDF overlap detected: %.3f sec between file %d and %d.', ...
            gapSec,k-1,k);
    end
end

%% ------------------------------------------------------------
% 4. Read EDF files
% ------------------------------------------------------------

dataAll = [];

sourceFile = strings(nFiles,1);

for k = 1:nFiles

    fprintf('Reading EDF %d/%d: %s\n', ...
        k,nFiles,qc.EDFFile{k});

    TT = edfread(qc.EDFPath{k});

    nChannels = numel(labelsRef);

    % timetable内の各cellを連続ベクトル化
    fileData = [];

    for ch = 1:nChannels

        varName = TT.Properties.VariableNames{ch};

        xCell = TT.(varName);

        x = vertcat(xCell{:});

        if ch == 1
            fileData = NaN(length(x),nChannels);
        end

        fileData(:,ch) = double(x);
    end

    sourceFile(k) = string(qc.EDFFile{k});

    %% --------------------------------------------------------
    % 5. File boundary処理
    % --------------------------------------------------------

   
if k == 1

    dataAll = fileData;

else

    gapSec = qc.GapFromPreviousSec(k);

    if gapSec < -2

        error( ...
            'Large EDF overlap detected: %.3f sec between file %d and %d.', ...
            gapSec,k-1,k);

    elseif gapSec < 0

        % 小さなoverlap：
        % 次ファイル冒頭の重複サンプルを削除
        nOverlapSamples = round(abs(gapSec) * fsRaw);

        fprintf( ...
            '  Trimming %.3f-sec overlap (%d samples)\n', ...
            abs(gapSec),nOverlapSamples);

        if nOverlapSamples >= size(fileData,1)
            error('Overlap exceeds file length.');
        end

        fileData = fileData(nOverlapSamples+1:end,:);

        dataAll = [dataAll; fileData];

    elseif gapSec > 0

        % positive gap：
        % 小さなものも含めNaNとして実時間を保持
        nGapSamples = round(gapSec * fsRaw);

        fprintf( ...
            '  Preserving %.3f-sec gap (%d samples)\n', ...
            gapSec,nGapSamples);

        gapData = NaN(nGapSamples,nChannels);

        dataAll = [dataAll; gapData; fileData];

    else

        % gap = 0
        dataAll = [dataAll; fileData];

    end
end
end

%% ------------------------------------------------------------
% 6. Timeline
% ------------------------------------------------------------

nSamples = size(dataAll,1);

timeSec = (0:nSamples-1)' / fsRaw;

%% ------------------------------------------------------------
% 7. Output
% ------------------------------------------------------------

out = struct;

out.Data = dataAll;
out.Fs = fsRaw;
out.Labels = labelsRef;
out.TimeSec = timeSec;
out.FileQC = qc;
out.SourceFiles = sourceFile;
out.DurationSec = nSamples / fsRaw;

fprintf('\nEDF loading complete.\n');
fprintf('Files       : %d\n',nFiles);
fprintf('Fs          : %.0f Hz\n',fsRaw);
fprintf('Channels    : %d\n',numel(labelsRef));
fprintf('Duration    : %.2f min\n',out.DurationSec/60);

end