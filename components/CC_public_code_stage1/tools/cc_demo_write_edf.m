function cc_demo_write_edf(fileName, data, fs, startSec)
%CC_DEMO_WRITE_EDF Write NEW synthetic samples with an explicitly fictional header.
% All data are interpreted as physical microvolt values. No patient header is read.
validateattributes(data, {'double'}, {'2d','real','finite','nonempty'});
validateattributes(fs, {'numeric'}, {'scalar','integer','positive'});
validateattributes(startSec, {'numeric'}, {'scalar','integer','nonnegative','<',86400});
assert(mod(size(data,1), fs)==0, 'CCDemo:EDFDur', ...
    'Synthetic EDF duration must be an integer number of seconds.');
assert(max(abs(data),[],'all') < 200, 'CCDemo:EDFLimits', ...
    'Synthetic samples exceed the fixed physical range.');
assert(~isfile(fileName), 'CCDemo:NoOverwrite', 'Refusing to overwrite an EDF.');
nCh = size(data,2);
hdr = edfheader('EDF');
hdr.Patient = 'SYNTHETIC_ONLY_NOT_A_PATIENT';
hdr.Recording = 'ARTIFICIAL_SOFTWARE_TEST';
hdr.StartDate = '01.01.00'; % Fictional date; not the clinical acquisition date.
hdr.StartTime = sprintf('%02d.%02d.%02d', floor(startSec/3600), ...
    mod(floor(startSec/60),60), mod(startSec,60));
hdr.NumSignals = nCh;
hdr.NumDataRecords = size(data,1)/fs;
hdr.DataRecordDuration = seconds(1);
hdr.SignalLabels = "POL A" + string(1:nCh);
hdr.PhysicalDimensions = repmat("uV",1,nCh);
hdr.PhysicalMin = -200*ones(1,nCh);
hdr.PhysicalMax = 200*ones(1,nCh);
hdr.DigitalMin = -32768*ones(1,nCh);
hdr.DigitalMax = 32767*ones(1,nCh);
hdr.TransducerTypes = repmat("SYNTHETIC",1,nCh);
hdr.Prefilter = repmat("None",1,nCh);
writer = edfwrite(fileName,hdr,data,'InputSampleType','physical'); %#ok<NASGU>
clear writer
assert(isfile(fileName), 'CCDemo:EDFNotWritten','Synthetic EDF was not created.');
end
