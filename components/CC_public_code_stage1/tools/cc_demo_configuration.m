function config = cc_demo_configuration()
%CC_DEMO_CONFIGURATION New self-contained test configuration, not a clinical file.
% Processing settings follow the supplied pipeline/manuscript.
% The artificial duration, ID and event times live in cc_demo_make_recording.
config.analysisVersion = 'SYNTHETIC_STAGE1_CANDIDATE';
config.allowedEDFsamplingRates = [500 1000 2000];
config.targetSamplingRate = 200;
config.epochSec = 30;
config.analysisFilterHz = [1 40];
config.primaryFrequencyBandHz = [4 13];
config.artifactMaxAbs_uV = 1000;
config.artifactRange_uV = 2000;
config.artifactFlatSD_uV = 0.5;
config.baselineSearchWindowSec = 600;
config.baselineCleanDurationSec = 300;
config.minPreEpochs = 10;
config.postGuardSec = 120;
config.postSearchWindowSec = 600;
config.minPostEpochs = 3;
config.maxPostEpochs = 10;
end
