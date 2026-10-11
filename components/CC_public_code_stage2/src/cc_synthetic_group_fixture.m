function F = cc_synthetic_group_fixture()
%CC_SYNTHETIC_GROUP_FIXTURE Artificial SUMMARY inputs, not simulated patients.
% No clinical records, clinical effect sizes or clinical missingness counts
% are used. These tables do not come from the stage-1 artificial EDFs.
% Purpose: exercise selection, grouping, missingness and LMM interfaces.
oldRng=rng; cleaner=onCleanup(@() rng(oldRng)); %#ok<NASGU>
rng(104729,'twister');
n=24;
states=["Pre","Anterior","Posterior","Post"];
regions=["CP","FT","PO","T","TO"];
starts={0:30:330,360:30:450,480:30:600,750:30:1080};
rows=cell(0,15);
patientEffect=0.28*randn(n,1);
regionEffect=0.20*randn(1,5);
% Non-monotonic arbitrary patterns used to exercise the model design only.
statePattern=[0 0.035 -0.020 0.010];
metricPattern=0.06*randn(8,4);
for c=1:n
    for r=1:5
        pr=0.18*randn;
        for s=1:4
            cs=0.06*randn;
            for k=1:numel(starts{s})
                t=starts{s}(k);
                latent=patientEffect(c)+regionEffect(r)+pr+cs+statePattern(s);
                w=1/(1+exp(-(latent+0.10*randn)));
                dw=0.03+0.03*latent+0.02*randn;
                bands=zeros(1,4);
                for b=1:4
                    bands(b)=1/(1+exp(-(latent+metricPattern(b,s)+0.09*randn)));
                end
                rmsv=exp(2.6+0.25*latent+metricPattern(5,s)+0.08*randn);
                pow=exp(5.1+0.35*latent+metricPattern(6,s)+0.12*randn);
                rel=1/(1+exp(-(-0.25+0.3*latent+metricPattern(7,s)+0.06*randn)));
                bad=(c==1 && s==1 && k<=3) || ...
                    (c==3 && s==4 && k>2);
                % Negative dwPLI is permitted; no clipping is applied.
                rows(end+1,:)={string(910000+c),states(s),regions(r),t,bad, ...
                    w,dw,bands(1),bands(2),bands(3),bands(4),rmsv,pow,rel,k}; %#ok<AGROW>
            end
        end
    end
end
E=cell2table(rows,'VariableNames',{'CaseNo','State','Region','StartSec', ...
    'RegionBad','MeanWTC_4_13','MeanDwPLI_4_13','MeanWTC_Delta', ...
    'MeanWTC_Theta','MeanWTC_Alpha','MeanWTC_Beta','MeanRMS', ...
    'MeanPower1_40','RelativePower4_13','StateEpoch'});
% Original helper interfaces accept canonical string grouping keys.
E.CaseNo=string(E.CaseNo); E.State=string(E.State); E.Region=string(E.Region);
E.RegionBad=logical(E.RegionBad);

exactRows=cell(0,4);
for c=1:n
    for s=1:4
        if c==2 && s==1, continue; end % Separate-source missingness.
        noise=0.045*randn(1,2);
        for t=1:2
            conn=["Intra","Inter"];
            y=1/(1+exp(-(patientEffect(c)+statePattern(s)+noise(t)+0.015*(t-1))));
            exactRows(end+1,:)={string(910000+c),states(s),conn(t),y}; %#ok<AGROW>
        end
    end
end
X=cell2table(exactRows,'VariableNames',{'CaseNo','State','ConnectionType','MeanWTC'});
X.CaseNo=string(X.CaseNo); X.State=string(X.State);
X.ConnectionType=string(X.ConnectionType);
F=struct;
F.Epochs=E; F.Exact=X;
F.Rules=struct('PreMin',10,'PostMin',3,'PostMax',10);
% An explicit, fictional REGION exclusion is applied AFTER selection.
% It is not a real-study exclusion list, and no threshold is inferred.
F.ExcludedGroup=table("910004","Pre","CP", ...
    'VariableNames',{'CaseNo','State','Region'});
F.NumberOfArtificialSubjects=n;
F.Description='24 fictional subjects; arbitrary summaries; no clinical records used';
end
