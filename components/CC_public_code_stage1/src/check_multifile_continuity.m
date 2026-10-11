function qc = check_multifile_continuity(caseFolder)
% CHECK_MULTIFILE_CONTINUITY
% Split EDF filesの開始時刻・終了時刻・gap/overlapを確認する

edfFiles = dir(fullfile(caseFolder,'*.edf'));

if isempty(edfFiles)
    error('EDF file not found: %s',caseFolder);
end

rows = {};

for k = 1:numel(edfFiles)

    path = fullfile(edfFiles(k).folder,edfFiles(k).name);
    info = edfinfo(path);

    fs = unique( ...
        info.NumSamples ./ seconds(info.DataRecordDuration));

    durationSec = ...
        info.NumDataRecords * seconds(info.DataRecordDuration);

    dateStr = string(info.StartDate);
    timeStr = string(info.StartTime);

    % EDF header format: dd.MM.yy HH.mm.ss
    startDT = datetime( ...
        dateStr + " " + timeStr, ...
        'InputFormat','dd.MM.yy HH.mm.ss', ...
        'PivotYear',2000);

    endDT = startDT + seconds(durationSec);

    rows(end+1,:) = { ...
        string(edfFiles(k).name), ...
        path, ...
        fs(1), ...
        numel(info.SignalLabels), ...
        startDT, ...
        endDT, ...
        durationSec};
end

qc = cell2table(rows, ...
    'VariableNames', ...
    {'EDFFile','EDFPath','SamplingRateHz','Channels', ...
    'StartDateTime','EndDateTime','DurationSec'});

% 実時間順に並べる
qc = sortrows(qc,'StartDateTime');

% 前ファイル終了 → 次ファイル開始
qc.GapFromPreviousSec = NaN(height(qc),1);

for k = 2:height(qc)

    qc.GapFromPreviousSec(k) = ...
        seconds(qc.StartDateTime(k) - qc.EndDateTime(k-1));
end

end