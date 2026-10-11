function [eventRow, fixture] = cc_demo_make_recording(caseDir)
%CC_DEMO_MAKE_RECORDING NEW stationary synthetic recording and artificial events.
% This is not simulated surgery, a fitted biological model or patient-derived data.
% No monotonic change is imposed or required. Event labels exercise software only.
assert(isfolder(caseDir), 'CCDemo:Folder','Synthetic input folder is absent.');
assert(isempty(dir(fullfile(caseDir,'*.edf'))), 'CCDemo:NoOverwrite', ...
    'Synthetic input folder must not already contain EDFs.');
fixture.Fs = 500;
fixture.DurationSec = 630;
fixture.AnteriorStartSec = 330;
fixture.TransitionSec = 360;
fixture.CompleteSec = 390;
fixture.SplitSec = 315;
fixture.Seed = 20261011;
fixture.ArtificialID = 900001;
rs = RandStream('mt19937ar','Seed',fixture.Seed);
t = (0:(fixture.DurationSec*fixture.Fs-1))'/fixture.Fs;
n = numel(t);
X = zeros(n,16);
for pair = 1:6
    f = 4.5 + pair;
    phase = 0.17*pair;
    common = sin(2*pi*f*t + phase) + 0.45*cos(2*pi*2.5*t + phase/2);
    X(:,2*pair-1) = 12*common + 8*randn(rs,n,1);
    X(:,2*pair) = 12*(sin(2*pi*f*t + phase + 0.4) + ...
        0.45*cos(2*pi*2.5*t + phase/2)) + 8*randn(rs,n,1);
end
X(:,13:16) = 5*randn(rs,n,4);
k = fixture.SplitSec*fixture.Fs;
cc_demo_write_edf(fullfile(caseDir,'synthetic_part01.edf'),X(1:k,:), ...
    fixture.Fs,0);
cc_demo_write_edf(fullfile(caseDir,'synthetic_part02.edf'),X(k+1:end,:), ...
    fixture.Fs,fixture.SplitSec);
% The original function accesses eventRow columns 2,8,10,12 positionally.
% Provide only a new numeric test table; never read the clinical Excel sheet.
v = nan(1,12);
v([1 2 8 10 12]) = [1 fixture.ArtificialID fixture.AnteriorStartSec ...
    fixture.TransitionSec fixture.CompleteSec];
eventRow = array2table(v,'VariableNames',cellstr("DemoColumn"+string(1:12)));
end
